#!/usr/bin/env python3
import argparse
from dataclasses import dataclass
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
        if t == '(':
            out: List[Node] = []
            while idx < len(tokens) and tokens[idx] != ')':
                out.append(parse_one())
            if idx >= len(tokens) or tokens[idx] != ')':
                raise ParseError("missing )")
            idx += 1
            return out
        if t == ')':
            raise ParseError("unexpected )")
        return t

    root = parse_one()
    if idx != len(tokens):
        raise ParseError("extra tokens after root")
    return root


@dataclass
class Ctx:
    locals: List[str]
    string_addrs: Dict[str, int]
    fn_names: Set[str]

    def local_index(self, name: str) -> int:
        if name not in self.locals:
            raise LowerError(f"unknown local: {name}")
        return self.locals.index(name)

    def string_addr(self, token: str) -> int:
        if token not in self.string_addrs:
            raise LowerError("missing string literal in string table")
        return self.string_addrs[token]


WAT_OPS = {
    "add": "i32.add",
    "sub": "i32.sub",
    "mul": "i32.mul",
    "div": "i32.div_s",
    "eq": "i32.eq",
    "ne": "i32.ne",
    "lt": "i32.lt_s",
    "gt": "i32.gt_s",
    "le": "i32.le_s",
    "ge": "i32.ge_s",
}


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


def wat_escape_bytes(data: bytes) -> str:
    out: List[str] = []
    for b in data:
        if 32 <= b <= 126 and b not in (34, 92):
            out.append(chr(b))
        else:
            out.append(f"\\{b:02x}")
    return "".join(out)


def walk_expr_for_strings(expr: Node, out: Dict[str, None]) -> None:
    e = as_list(expr)
    tag = as_atom(e[0])
    if tag == "string":
        out[as_atom(e[1])] = None
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
    return list(found.keys())


def collect_features_expr(expr: Node, out: Dict[str, bool]) -> None:
    e = as_list(expr)
    tag = as_atom(e[0])
    if tag == "call":
        callee = as_atom(e[1])
        if callee == "__fd_write":
            out["fd_write"] = True
        for arg in e[2:]:
            collect_features_expr(arg, out)
    elif tag == "binary":
        collect_features_expr(e[2], out)
        collect_features_expr(e[3], out)


def collect_features(block: Node) -> Dict[str, bool]:
    b = as_list(block)
    out = {"fd_write": False}
    for stmt in b[1:]:
        s = as_list(stmt)
        tag = as_atom(s[0])
        if tag == "let":
            collect_features_expr(s[3], out)
        elif tag == "assign":
            collect_features_expr(s[2], out)
        elif tag == "return":
            collect_features_expr(s[1], out)
        elif tag == "expr":
            collect_features_expr(s[1], out)
    return out


def emit_expr(expr: Node, ctx: Ctx, out: List[str]) -> None:
    e = as_list(expr)
    if not e:
        raise LowerError("empty expr")
    tag = as_atom(e[0])
    if tag == "int":
        out.append(f"    i32.const {as_atom(e[1])}")
        return
    if tag == "bool":
        out.append(f"    i32.const {as_atom(e[1])}")
        return
    if tag == "ident":
        idx = ctx.local_index(as_atom(e[1]))
        out.append(f"    local.get {idx}")
        return
    if tag == "string":
        addr = ctx.string_addr(as_atom(e[1]))
        out.append(f"    i32.const {addr}")
        return
    if tag == "binary":
        op = as_atom(e[1])
        op_wat = WAT_OPS.get(op)
        if not op_wat:
            raise LowerError(f"unsupported binary op: {op}")
        emit_expr(e[2], ctx, out)
        emit_expr(e[3], ctx, out)
        out.append(f"    {op_wat}")
        return
    if tag == "call":
        callee = as_atom(e[1])
        args = e[2:]
        if callee == "__mem_store":
            if len(args) != 2:
                raise LowerError("__mem_store expects 2 args")
            emit_expr(args[0], ctx, out)
            emit_expr(args[1], ctx, out)
            out.append("    i32.store")
            out.append("    i32.const 0")
            return
        if callee == "__mem_store8":
            if len(args) != 2:
                raise LowerError("__mem_store8 expects 2 args")
            emit_expr(args[0], ctx, out)
            emit_expr(args[1], ctx, out)
            out.append("    i32.store8")
            out.append("    i32.const 0")
            return
        if callee == "__mem_load":
            if len(args) != 1:
                raise LowerError("__mem_load expects 1 arg")
            emit_expr(args[0], ctx, out)
            out.append("    i32.load")
            return
        if callee == "__mem_load8":
            if len(args) != 1:
                raise LowerError("__mem_load8 expects 1 arg")
            emit_expr(args[0], ctx, out)
            out.append("    i32.load8_u")
            return
        if callee == "__fd_write":
            if len(args) != 4:
                raise LowerError("__fd_write expects 4 args")
            for arg in args:
                emit_expr(arg, ctx, out)
            out.append("    call $fd_write")
            return
        if callee not in ctx.fn_names:
            raise LowerError(f"unsupported call: {callee}")
        for arg in args:
            emit_expr(arg, ctx, out)
        out.append(f"    call ${callee}")
        return
    raise LowerError(f"unsupported expr: {tag}")


def emit_stmt(stmt: Node, ctx: Ctx, out: List[str]) -> None:
    s = as_list(stmt)
    tag = as_atom(s[0])
    if tag == "let":
        name = as_atom(s[1])
        ty = as_atom(s[2])
        if ty != "i32":
            raise LowerError(f"unsupported let type: {ty}")
        emit_expr(s[3], ctx, out)
        idx = ctx.local_index(name)
        out.append(f"    local.set {idx}")
        return
    if tag == "assign":
        name = as_atom(s[1])
        emit_expr(s[2], ctx, out)
        idx = ctx.local_index(name)
        out.append(f"    local.set {idx}")
        return
    if tag == "return":
        emit_expr(s[1], ctx, out)
        out.append("    return")
        return
    if tag == "expr":
        emit_expr(s[1], ctx, out)
        out.append("    drop")
        return
    raise LowerError(f"unsupported stmt: {tag}")


def collect_locals(block: Node) -> List[str]:
    b = as_list(block)
    if as_atom(b[0]) != "block":
        raise LowerError("expected block")
    locals_: List[str] = []
    for stmt in b[1:]:
        s = as_list(stmt)
        if as_atom(s[0]) == "let":
            locals_.append(as_atom(s[1]))
    return locals_


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
        if len(pl) != 3 or as_atom(pl[0]) != "param" or as_atom(pl[2]) != "i32":
            raise LowerError("only i32 params supported")
        params.append(as_atom(pl[1]))
    ret = as_list(fn_node[3])
    if len(ret) != 2 or as_atom(ret[0]) != "ret" or as_atom(ret[1]) != "i32":
        raise LowerError("only (ret i32) supported")
    block = as_list(fn_node[4])
    return name, params, block


def lower_function(name: str, params: List[str], block: Node, string_addrs: Dict[str, int], fn_names: Set[str]) -> List[str]:
    let_locals = collect_locals(block)
    all_locals = params + let_locals
    ctx = Ctx(all_locals, string_addrs, fn_names)

    body: List[str] = []
    for stmt in as_list(block)[1:]:
        emit_stmt(stmt, ctx, body)

    lines: List[str] = []
    param_sig = " ".join("(param i32)" for _ in params)
    if param_sig:
        lines.append(f"  (func ${name} {param_sig} (result i32)")
    else:
        lines.append(f"  (func ${name} (result i32)")
    for _ in let_locals:
        lines.append("    (local i32)")
    lines.extend(body)
    lines.append("  )")
    return lines


def lower_ir(root: Node) -> str:
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

    fn_nodes = [as_list(f) for f in functions[1:]]
    parsed = [parse_fn(f) for f in fn_nodes]

    mains = [name for (name, _, _) in parsed if name == "main"]
    if len(mains) != 1:
        raise LowerError("expected exactly one main function")

    features = {"fd_write": False}
    string_tokens: Dict[str, None] = {}
    for _, _, block in parsed:
        fb = collect_features(block)
        features["fd_write"] = features["fd_write"] or fb["fd_write"]
        for tok in collect_string_literals(block):
            string_tokens[tok] = None

    string_addrs: Dict[str, int] = {}
    data_segments: List[Tuple[int, bytes]] = []
    cur_addr = 1024
    for tok in string_tokens.keys():
        b = decode_string_token(tok)
        string_addrs[tok] = cur_addr
        data_segments.append((cur_addr, b))
        cur_addr += len(b)
        if cur_addr % 4 != 0:
            cur_addr += 4 - (cur_addr % 4)

    fn_names: Set[str] = {name for (name, _, _) in parsed}

    lines: List[str] = []
    lines.append("(module")
    if features["fd_write"]:
        lines.append("  (import \"wasi_snapshot_preview1\" \"fd_write\"")
        lines.append("    (func $fd_write (param i32 i32 i32 i32) (result i32)))")
    lines.append("  (memory (export \"memory\") 2)")
    for addr, data in data_segments:
        lines.append(f"  (data (i32.const {addr}) \"{wat_escape_bytes(data)}\")")

    for name, params, block in parsed:
        lines.extend(lower_function(name, params, block, string_addrs, fn_names))

    lines.append("  (export \"main\" (func $main))")
    lines.append(")")
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="Lower Mee IR (subset) to WAT")
    ap.add_argument("input", help="input .ir file")
    ap.add_argument("-o", "--output", required=True, help="output .wat file")
    args = ap.parse_args()

    src = Path(args.input).read_text()
    toks = tokenize(src)
    root = parse_sexpr(toks)
    wat = lower_ir(root)
    Path(args.output).write_text(wat)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
