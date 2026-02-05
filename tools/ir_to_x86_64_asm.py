#!/usr/bin/env python3
import argparse
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple, Union

Node = Union[str, List["Node"]]


class ParseError(Exception):
    pass


class LowerError(Exception):
    pass


def tokenize(src: str) -> List[str]:
    toks: List[str] = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c.isspace():
            i += 1
            continue
        if c in "()":
            toks.append(c)
            i += 1
            continue
        if c == '"':
            j = i + 1
            esc = False
            while j < n:
                ch = src[j]
                if esc:
                    esc = False
                elif ch == '\\':
                    esc = True
                elif ch == '"':
                    break
                j += 1
            if j >= n:
                raise ParseError("unterminated string")
            toks.append(src[i:j + 1])
            i = j + 1
            continue
        j = i
        while j < n and (not src[j].isspace()) and src[j] not in "()":
            j += 1
        toks.append(src[i:j])
        i = j
    return toks


def parse_sexpr(tokens: List[str]) -> Node:
    idx = 0

    def parse_one() -> Node:
        nonlocal idx
        if idx >= len(tokens):
            raise ParseError("unexpected EOF")
        t = tokens[idx]
        idx += 1
        if t == "(":
            out: List[Node] = []
            while idx < len(tokens) and tokens[idx] != ")":
                out.append(parse_one())
            if idx >= len(tokens) or tokens[idx] != ")":
                raise ParseError("missing )")
            idx += 1
            return out
        if t == ")":
            raise ParseError("unexpected )")
        return t

    root = parse_one()
    if idx != len(tokens):
        raise ParseError("extra tokens after root")
    return root


def as_list(node: Node) -> List[Node]:
    if not isinstance(node, list):
        raise LowerError("expected list node")
    return node


def as_atom(node: Node) -> str:
    if isinstance(node, list):
        raise LowerError("expected atom")
    return node


def decode_string_token(tok: str) -> bytes:
    if len(tok) < 2 or tok[0] != '"' or tok[-1] != '"':
        raise LowerError("invalid string token")
    inner = tok[1:-1]
    text = bytes(inner, "utf-8").decode("unicode_escape")
    return text.encode("utf-8")


def c_escape_bytes(data: bytes) -> str:
    out: List[str] = []
    for b in data:
        if 32 <= b <= 126 and b not in (34, 92):
            out.append(chr(b))
        else:
            out.append(f"\\x{b:02x}")
    return "".join(out)


def walk_expr_for_strings(expr: Node, out: Dict[str, None]) -> None:
    e = as_list(expr)
    tag = as_atom(e[0])
    if tag == "string":
        out[as_atom(e[1])] = None
        return
    if tag == "unary":
        walk_expr_for_strings(e[2], out)
        return
    if tag == "binary":
        walk_expr_for_strings(e[2], out)
        walk_expr_for_strings(e[3], out)
        return
    if tag == "call":
        for arg in e[2:]:
            walk_expr_for_strings(arg, out)
        return


def collect_string_literals(block: Node) -> List[str]:
    b = as_list(block)
    if as_atom(b[0]) != "block":
        raise LowerError("expected block")
    found: Dict[str, None] = {}
    for stmt in b[1:]:
        s = as_list(stmt)
        tag = as_atom(s[0])
        if tag == "let":
            walk_expr_for_strings(s[3], found)
        elif tag == "assign":
            walk_expr_for_strings(s[2], found)
        elif tag == "return":
            walk_expr_for_strings(s[1], found)
        elif tag == "expr":
            walk_expr_for_strings(s[1], found)
        elif tag == "if":
            walk_expr_for_strings(s[1], found)
            for tok in collect_string_literals(s[2]):
                found[tok] = None
            if len(s) > 3:
                eb = as_list(s[3])
                if as_atom(eb[0]) == "else":
                    for tok in collect_string_literals(eb[1]):
                        found[tok] = None
        elif tag == "while":
            walk_expr_for_strings(s[1], found)
            for tok in collect_string_literals(s[2]):
                found[tok] = None
    return list(found.keys())


def parse_fn(fn_node: List[Node]) -> Tuple[str, List[str], Node]:
    if len(fn_node) != 5 or as_atom(fn_node[0]) != "fn":
        raise LowerError("function shape not supported")
    name = as_atom(fn_node[1])
    params_node = as_list(fn_node[2])
    if as_atom(params_node[0]) != "params":
        raise LowerError("invalid params section")
    params: List[str] = []
    for p in params_node[1:]:
        pl = as_list(p)
        if len(pl) != 3 or as_atom(pl[0]) != "param":
            raise LowerError("only i32 params supported")
        if isinstance(pl[2], list) or as_atom(pl[2]) != "i32":
            raise LowerError("only i32 params supported")
        params.append(as_atom(pl[1]))
    ret = as_list(fn_node[3])
    if len(ret) != 2 or as_atom(ret[0]) != "ret":
        raise LowerError("only (ret i32) supported")
    if isinstance(ret[1], list) or as_atom(ret[1]) != "i32":
        raise LowerError("only (ret i32) supported")
    block = as_list(fn_node[4])
    return name, params, block


def collect_locals(block: Node, out: Set[str]) -> None:
    b = as_list(block)
    if as_atom(b[0]) != "block":
        raise LowerError("expected block")
    for stmt in b[1:]:
        s = as_list(stmt)
        tag = as_atom(s[0])
        if tag == "let":
            out.add(as_atom(s[1]))
        elif tag == "if":
            collect_locals(s[2], out)
            if len(s) > 3:
                eb = as_list(s[3])
                if as_atom(eb[0]) == "else":
                    collect_locals(eb[1], out)
        elif tag == "while":
            collect_locals(s[2], out)


class Ctx:
    def __init__(self, string_addrs: Dict[str, int], fn_cnames: Dict[str, str]):
        self.string_addrs = string_addrs
        self.fn_cnames = fn_cnames


OP_MAP = {
    "add": "+",
    "sub": "-",
    "mul": "*",
    "div": "/",
    "eq": "==",
    "ne": "!=",
    "lt": "<",
    "gt": ">",
    "le": "<=",
    "ge": ">=",
    "and": "&",
    "or": "|",
}


def expr_to_c(expr: Node, ctx: Ctx) -> str:
    e = as_list(expr)
    tag = as_atom(e[0])
    if tag == "int":
        return f"((int32_t){as_atom(e[1])})"
    if tag == "bool":
        return f"((int32_t){as_atom(e[1])})"
    if tag == "ident":
        return as_atom(e[1])
    if tag == "string":
        tok = as_atom(e[1])
        if tok not in ctx.string_addrs:
            raise LowerError("missing string literal address")
        return f"((int32_t){ctx.string_addrs[tok]})"
    if tag == "binary":
        op = as_atom(e[1])
        if op not in OP_MAP:
            raise LowerError(f"unsupported binary op: {op}")
        left = expr_to_c(e[2], ctx)
        right = expr_to_c(e[3], ctx)
        if op in ("eq", "ne", "lt", "gt", "le", "ge"):
            return f"((int32_t)({left} {OP_MAP[op]} {right}))"
        return f"((int32_t)({left} {OP_MAP[op]} {right}))"
    if tag == "call":
        fn = as_atom(e[1])
        args = ", ".join(expr_to_c(a, ctx) for a in e[2:])
        if fn in ctx.fn_cnames:
            return f"((int32_t){ctx.fn_cnames[fn]}({args}))"
        if fn.startswith("__"):
            return f"((int32_t){fn}({args}))"
        raise LowerError(f"unknown function call: {fn}")
    raise LowerError(f"unsupported expr: {tag}")


def emit_stmt(stmt: Node, ctx: Ctx, out: List[str], indent: str) -> None:
    s = as_list(stmt)
    tag = as_atom(s[0])
    if tag == "let":
        name = as_atom(s[1])
        out.append(f"{indent}{name} = {expr_to_c(s[3], ctx)};")
        return
    if tag == "assign":
        name = as_atom(s[1])
        out.append(f"{indent}{name} = {expr_to_c(s[2], ctx)};")
        return
    if tag == "return":
        out.append(f"{indent}return {expr_to_c(s[1], ctx)};")
        return
    if tag == "expr":
        out.append(f"{indent}(void){expr_to_c(s[1], ctx)};")
        return
    if tag == "if":
        out.append(f"{indent}if ({expr_to_c(s[1], ctx)}) {{")
        emit_block(s[2], ctx, out, indent + "  ")
        out.append(f"{indent}}}")
        if len(s) > 3:
            eb = as_list(s[3])
            if as_atom(eb[0]) == "else":
                out.append(f"{indent}else {{")
                emit_block(eb[1], ctx, out, indent + "  ")
                out.append(f"{indent}}}")
        return
    if tag == "while":
        out.append(f"{indent}while ({expr_to_c(s[1], ctx)}) {{")
        emit_block(s[2], ctx, out, indent + "  ")
        out.append(f"{indent}}}")
        return
    raise LowerError(f"unsupported stmt: {tag}")


def emit_block(block: Node, ctx: Ctx, out: List[str], indent: str) -> None:
    b = as_list(block)
    if as_atom(b[0]) != "block":
        raise LowerError("expected block")
    for stmt in b[1:]:
        emit_stmt(stmt, ctx, out, indent)


def lower_ir_to_c(root: Node) -> str:
    top = as_list(root)
    if len(top) != 4 or as_atom(top[0]) != "mee_ir":
        raise LowerError("unsupported IR root")
    if as_atom(top[1]) != "v0":
        raise LowerError("unsupported IR version")
    structs = as_list(top[2])
    if as_atom(structs[0]) != "structs":
        raise LowerError("invalid structs section")
    functions = as_list(top[3])
    if as_atom(functions[0]) != "functions":
        raise LowerError("invalid functions section")

    parsed = [parse_fn(as_list(f)) for f in functions[1:]]
    fn_names = {name for (name, _, _) in parsed}
    if "main" not in fn_names:
        raise LowerError("expected main function")
    fn_cnames: Dict[str, str] = {}
    for name in fn_names:
        if name == "main":
            fn_cnames[name] = "mee_user_main"
        else:
            fn_cnames[name] = f"mee_fn_{name}"

    str_tokens: Dict[str, None] = {}
    for _, _, block in parsed:
        for tok in collect_string_literals(block):
            str_tokens[tok] = None

    string_addrs: Dict[str, int] = {}
    next_addr = 65536
    string_entries: List[Tuple[int, bytes]] = []
    for tok in str_tokens.keys():
        data = decode_string_token(tok)
        addr = next_addr
        string_addrs[tok] = addr
        string_entries.append((addr, data))
        next_addr += len(data) + 1

    out: List[str] = []
    out.append("#include <stdint.h>")
    out.append("#include <stddef.h>")
    out.append("#include <string.h>")
    out.append("#include <unistd.h>")
    out.append("#include <fcntl.h>")
    out.append("#include <errno.h>")
    out.append("")
    out.append("static uint8_t __mee_mem[1 << 20];")
    out.append("static int __mee_mem_inited = 0;")
    out.append("")
    out.append("static void __mee_init_memory(void) {")
    out.append("  if (__mee_mem_inited) return;")
    out.append("  __mee_mem_inited = 1;")
    for addr, data in string_entries:
        esc = c_escape_bytes(data)
        out.append(f"  memcpy(__mee_mem + {addr}, \"{esc}\", {len(data)});")
    out.append("}")
    out.append("")
    out.append("static int32_t __mem_load(int32_t addr) {")
    out.append("  int32_t v = 0;")
    out.append("  memcpy(&v, __mee_mem + addr, 4);")
    out.append("  return v;")
    out.append("}")
    out.append("")
    out.append("static int32_t __mem_load8(int32_t addr) {")
    out.append("  return (int32_t)__mee_mem[addr];")
    out.append("}")
    out.append("")
    out.append("static int32_t __mem_store(int32_t addr, int32_t val) {")
    out.append("  memcpy(__mee_mem + addr, &val, 4);")
    out.append("  return 0;")
    out.append("}")
    out.append("")
    out.append("static int32_t __mem_store8(int32_t addr, int32_t val) {")
    out.append("  __mee_mem[addr] = (uint8_t)(val & 0xff);")
    out.append("  return 0;")
    out.append("}")
    out.append("")
    out.append("struct __mee_iovec32 { int32_t base; int32_t len; };")
    out.append("")
    out.append("static int32_t __fd_write(int32_t fd, int32_t iov_ptr, int32_t iov_cnt, int32_t nwritten_ptr) {")
    out.append("  int32_t total = 0;")
    out.append("  for (int32_t i = 0; i < iov_cnt; i++) {")
    out.append("    struct __mee_iovec32 iv;")
    out.append("    memcpy(&iv, __mee_mem + iov_ptr + i * 8, 8);")
    out.append("    ssize_t n = write(fd, __mee_mem + iv.base, (size_t)iv.len);")
    out.append("    if (n < 0) return (int32_t)errno;")
    out.append("    total += (int32_t)n;")
    out.append("  }")
    out.append("  __mem_store(nwritten_ptr, total);")
    out.append("  return 0;")
    out.append("}")
    out.append("")
    out.append("static int32_t __fd_read(int32_t fd, int32_t iov_ptr, int32_t iov_cnt, int32_t nread_ptr) {")
    out.append("  int32_t total = 0;")
    out.append("  for (int32_t i = 0; i < iov_cnt; i++) {")
    out.append("    struct __mee_iovec32 iv;")
    out.append("    memcpy(&iv, __mee_mem + iov_ptr + i * 8, 8);")
    out.append("    ssize_t n = read(fd, __mee_mem + iv.base, (size_t)iv.len);")
    out.append("    if (n < 0) return (int32_t)errno;")
    out.append("    total += (int32_t)n;")
    out.append("    if (n < iv.len) break;")
    out.append("  }")
    out.append("  __mem_store(nread_ptr, total);")
    out.append("  return 0;")
    out.append("}")
    out.append("")
    out.append("static int32_t __fd_close(int32_t fd) {")
    out.append("  if (close(fd) < 0) return (int32_t)errno;")
    out.append("  return 0;")
    out.append("}")
    out.append("")
    out.append("static int32_t __path_open(int32_t dirfd, int32_t dirflags, int32_t path_ptr, int32_t path_len, int32_t oflags, int64_t rights_base, int64_t rights_inh, int32_t fdflags, int32_t fd_out_ptr) {")
    out.append("  (void)dirfd; (void)dirflags; (void)rights_base; (void)rights_inh; (void)fdflags;")
    out.append("  char path_buf[4096];")
    out.append("  if (path_len < 0 || path_len >= (int32_t)sizeof(path_buf)) return 22;")
    out.append("  memcpy(path_buf, __mee_mem + path_ptr, (size_t)path_len);")
    out.append("  path_buf[path_len] = '\\0';")
    out.append("  int flags = O_RDONLY;")
    out.append("  if (oflags & 1) flags = O_WRONLY | O_CREAT | O_TRUNC;")
    out.append("  int fd = open(path_buf, flags, 0644);")
    out.append("  if (fd < 0) return (int32_t)errno;")
    out.append("  __mem_store(fd_out_ptr, (int32_t)fd);")
    out.append("  return 0;")
    out.append("}")
    out.append("")

    for name, params, block in parsed:
        sig = ", ".join(f"int32_t {p}" for p in params)
        out.append(f"static int32_t {fn_cnames[name]}({sig});")
    out.append("")

    ctx = Ctx(string_addrs, fn_cnames)
    for name, params, block in parsed:
        sig = ", ".join(f"int32_t {p}" for p in params)
        out.append(f"static int32_t {fn_cnames[name]}({sig}) {{")
        out.append("  __mee_init_memory();")
        locals_set: Set[str] = set()
        collect_locals(block, locals_set)
        params_set = set(params)
        for local in sorted(locals_set):
            if local in params_set:
                continue
            out.append(f"  int32_t {local} = 0;")
        emit_block(block, ctx, out, "  ")
        out.append("  return 0;")
        out.append("}")
        out.append("")

    out.append("int main(void) {")
    out.append(f"  return (int){fn_cnames['main']}();")
    out.append("}")
    out.append("")
    return "\n".join(out)

def lower_ir_to_asm(ir_path: Path, out_path: Path) -> None:
    src = ir_path.read_text()
    root = parse_sexpr(tokenize(src))
    c_src = lower_ir_to_c(root)
    with tempfile.TemporaryDirectory(prefix="mee-ir-x86-") as td:
        c_file = Path(td) / "module.c"
        c_file.write_text(c_src)
        cmd = ["gcc", "-S", "-O2", "-fno-asynchronous-unwind-tables", "-fno-stack-protector", "-no-pie", str(c_file), "-o", str(out_path)]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            raise LowerError(f"gcc failed:\n{proc.stderr}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Lower mee_ir v0 to x86_64 assembly via C (non-Rust path)")
    ap.add_argument("input", help="input .ir file")
    ap.add_argument("-o", "--output", required=True, help="output .s file")
    args = ap.parse_args()
    lower_ir_to_asm(Path(args.input), Path(args.output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
