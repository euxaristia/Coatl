#!/usr/bin/env python3
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple, Union

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
    if tag == "unary":
        walk_expr_for_strings(e[2], out)
        return
    if tag == "call":
        for arg in e[2:]:
            walk_expr_for_strings(arg, out)


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
        if as_atom(pl[2]) != "i32":
            raise LowerError("only i32 params supported")
        params.append(as_atom(pl[1]))
    ret = as_list(fn_node[3])
    if len(ret) != 2 or as_atom(ret[0]) != "ret" or as_atom(ret[1]) != "i32":
        raise LowerError("only (ret i32) supported")
    return name, params, as_list(fn_node[4])


def align16(n: int) -> int:
    return (n + 15) & ~15


ARG_REGS64 = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
ARG_REGS32 = ["edi", "esi", "edx", "ecx", "r8d", "r9d"]


class FnEmitter:
    def __init__(self, name: str, params: List[str], block: Node, string_addrs: Dict[str, int], fn_names: Set[str]):
        self.name = name
        self.params = params
        self.block = block
        self.string_addrs = string_addrs
        self.fn_names = fn_names
        self.lines: List[str] = []
        self.stack_depth = 0
        self.label_id = 0

        locals_set: Set[str] = set()
        collect_locals(block, locals_set)
        ordered_vars: List[str] = []
        seen: Set[str] = set()
        for p in params:
            ordered_vars.append(p)
            seen.add(p)
        for v in sorted(locals_set):
            if v not in seen:
                ordered_vars.append(v)
        self.var_off: Dict[str, int] = {v: (i + 1) * 8 for i, v in enumerate(ordered_vars)}
        self.stack_size = align16(len(ordered_vars) * 8)

    def emit(self, s: str) -> None:
        self.lines.append(s)

    def new_label(self, prefix: str) -> str:
        self.label_id += 1
        return f".L_{self.name}_{prefix}_{self.label_id}"

    def var_offset(self, name: str) -> int:
        if name not in self.var_off:
            raise LowerError(f"unknown local: {name}")
        return self.var_off[name]

    def push_rax(self) -> None:
        self.emit("  push rax")
        self.stack_depth += 1

    def pop_reg(self, reg64: str) -> None:
        self.emit(f"  pop {reg64}")
        self.stack_depth -= 1

    def emit_expr(self, expr: Node) -> None:
        e = as_list(expr)
        tag = as_atom(e[0])
        if tag == "int":
            self.emit(f"  mov eax, {as_atom(e[1])}")
            return
        if tag == "bool":
            self.emit(f"  mov eax, {as_atom(e[1])}")
            return
        if tag == "ident":
            off = self.var_offset(as_atom(e[1]))
            self.emit(f"  mov eax, dword ptr [rbp-{off}]")
            return
        if tag == "string":
            tok = as_atom(e[1])
            if tok not in self.string_addrs:
                raise LowerError("missing string literal address")
            self.emit(f"  mov eax, {self.string_addrs[tok]}")
            return
        if tag == "binary":
            op = as_atom(e[1])
            self.emit_expr(e[2])
            self.push_rax()
            self.emit_expr(e[3])
            self.emit("  mov ecx, eax")
            self.pop_reg("rax")
            if op == "add":
                self.emit("  add eax, ecx")
            elif op == "sub":
                self.emit("  sub eax, ecx")
            elif op == "mul":
                self.emit("  imul eax, ecx")
            elif op == "div":
                self.emit("  cdq")
                self.emit("  idiv ecx")
            elif op in ("eq", "ne", "lt", "gt", "le", "ge"):
                self.emit("  cmp eax, ecx")
                cc = {
                    "eq": "e",
                    "ne": "ne",
                    "lt": "l",
                    "gt": "g",
                    "le": "le",
                    "ge": "ge",
                }[op]
                self.emit(f"  set{cc} al")
                self.emit("  movzx eax, al")
            elif op == "and":
                self.emit("  and eax, ecx")
            elif op == "or":
                self.emit("  or eax, ecx")
            else:
                raise LowerError(f"unsupported binary op: {op}")
            return
        if tag == "call":
            fn = as_atom(e[1])
            args = e[2:]
            self.emit_call(fn, args)
            return
        raise LowerError(f"unsupported expr: {tag}")

    def emit_call(self, fn: str, args: List[Node]) -> None:
        if fn not in self.fn_names and not fn.startswith("__"):
            raise LowerError(f"unknown function call: {fn}")

        n = len(args)
        reg_n = min(n, 6)
        stack_n = max(0, n - 6)

        need_pad = (self.stack_depth + stack_n) % 2 == 1
        if need_pad:
            self.emit("  sub rsp, 8")
            self.stack_depth += 1

        for arg in reversed(args):
            self.emit_expr(arg)
            self.push_rax()

        for i in range(reg_n):
            self.pop_reg(ARG_REGS64[i])

        self.emit(f"  call {fn}")

        cleanup_slots = stack_n + (1 if need_pad else 0)
        if cleanup_slots:
            self.emit(f"  add rsp, {cleanup_slots * 8}")
            self.stack_depth -= cleanup_slots

    def emit_stmt(self, stmt: Node, ret_label: str) -> None:
        s = as_list(stmt)
        tag = as_atom(s[0])
        if tag == "let":
            name = as_atom(s[1])
            self.emit_expr(s[3])
            off = self.var_offset(name)
            self.emit(f"  mov dword ptr [rbp-{off}], eax")
            return
        if tag == "assign":
            name = as_atom(s[1])
            self.emit_expr(s[2])
            off = self.var_offset(name)
            self.emit(f"  mov dword ptr [rbp-{off}], eax")
            return
        if tag == "return":
            self.emit_expr(s[1])
            self.emit(f"  jmp {ret_label}")
            return
        if tag == "expr":
            self.emit_expr(s[1])
            return
        if tag == "if":
            else_label = self.new_label("else")
            end_label = self.new_label("ifend")
            self.emit_expr(s[1])
            self.emit("  test eax, eax")
            self.emit(f"  jz {else_label}")
            self.emit_block(s[2], ret_label)
            self.emit(f"  jmp {end_label}")
            self.emit(f"{else_label}:")
            if len(s) > 3:
                eb = as_list(s[3])
                if as_atom(eb[0]) == "else":
                    self.emit_block(eb[1], ret_label)
            self.emit(f"{end_label}:")
            return
        if tag == "while":
            cond_label = self.new_label("while_cond")
            end_label = self.new_label("while_end")
            self.emit(f"{cond_label}:")
            self.emit_expr(s[1])
            self.emit("  test eax, eax")
            self.emit(f"  jz {end_label}")
            self.emit_block(s[2], ret_label)
            self.emit(f"  jmp {cond_label}")
            self.emit(f"{end_label}:")
            return
        raise LowerError(f"unsupported stmt: {tag}")

    def emit_block(self, block: Node, ret_label: str) -> None:
        b = as_list(block)
        if as_atom(b[0]) != "block":
            raise LowerError("expected block")
        for stmt in b[1:]:
            self.emit_stmt(stmt, ret_label)

    def emit_function(self) -> List[str]:
        ret_label = f".L_{self.name}_ret"
        out: List[str] = []
        out.append(f".globl {self.name}")
        out.append(f"{self.name}:")
        out.append("  push rbp")
        out.append("  mov rbp, rsp")
        if self.stack_size:
            out.append(f"  sub rsp, {self.stack_size}")

        for i, p in enumerate(self.params):
            off = self.var_offset(p)
            if i < 6:
                out.append(f"  mov dword ptr [rbp-{off}], {ARG_REGS32[i]}")
            else:
                stack_off = 16 + (i - 6) * 8
                out.append(f"  mov eax, dword ptr [rbp+{stack_off}]")
                out.append(f"  mov dword ptr [rbp-{off}], eax")

        out.append("  call __coatl_init_memory")
        self.lines = []
        self.stack_depth = 0
        self.emit_block(self.block, ret_label)
        if self.stack_depth != 0:
            raise LowerError(f"internal stack depth mismatch in {self.name}: {self.stack_depth}")
        out.extend(self.lines)
        out.append("  mov eax, 0")
        out.append(f"{ret_label}:")
        out.append("  leave")
        out.append("  ret")
        out.append("")
        return out


def lower_ir_to_asm_text(root: Node) -> str:
    top = as_list(root)
    if len(top) != 4 or as_atom(top[0]) != "coatl_ir" or as_atom(top[1]) != "v0":
        raise LowerError("unsupported IR root/version")

    structs = as_list(top[2])
    if as_atom(structs[0]) != "structs":
        raise LowerError("invalid structs section")

    functions = as_list(top[3])
    if as_atom(functions[0]) != "functions":
        raise LowerError("invalid functions section")

    parsed = [parse_fn(as_list(f)) for f in functions[1:]]
    fn_names: Set[str] = {name for name, _, _ in parsed}
    if "main" not in fn_names:
        raise LowerError("expected main function")

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
        string_entries.append((addr, data + b"\x00"))
        next_addr += len(data) + 1

    out: List[str] = []
    out.append(".intel_syntax noprefix")
    out.append(".bss")
    out.append(".align 16")
    out.append("__coatl_mem:")
    out.append("  .zero 1048576")
    out.append(".align 4")
    out.append("__coatl_mem_inited:")
    out.append("  .long 0")
    out.append("")

    out.append(".text")
    out.append("__coatl_init_memory:")
    out.append("  push rbp")
    out.append("  mov rbp, rsp")
    out.append("  mov eax, dword ptr [rip+__coatl_mem_inited]")
    out.append("  test eax, eax")
    out.append("  jne .L_mem_done")
    out.append("  mov dword ptr [rip+__coatl_mem_inited], 1")
    out.append("  lea rdx, [rip+__coatl_mem]")
    for addr, data in string_entries:
        for i, b in enumerate(data):
            out.append(f"  mov byte ptr [rdx+{addr + i}], 0x{b:02x}")
    out.append(".L_mem_done:")
    out.append("  pop rbp")
    out.append("  ret")
    out.append("")

    out.append("__mem_load:")
    out.append("  mov eax, edi")
    out.append("  cdqe")
    out.append("  lea rdx, [rip+__coatl_mem]")
    out.append("  mov eax, dword ptr [rdx+rax]")
    out.append("  ret")
    out.append("")

    out.append("__mem_load8:")
    out.append("  mov eax, edi")
    out.append("  cdqe")
    out.append("  lea rdx, [rip+__coatl_mem]")
    out.append("  movzx eax, byte ptr [rdx+rax]")
    out.append("  ret")
    out.append("")

    out.append("__mem_store:")
    out.append("  mov eax, edi")
    out.append("  cdqe")
    out.append("  lea rdx, [rip+__coatl_mem]")
    out.append("  mov dword ptr [rdx+rax], esi")
    out.append("  xor eax, eax")
    out.append("  ret")
    out.append("")

    out.append("__mem_store8:")
    out.append("  mov eax, edi")
    out.append("  cdqe")
    out.append("  lea rdx, [rip+__coatl_mem]")
    out.append("  mov byte ptr [rdx+rax], sil")
    out.append("  xor eax, eax")
    out.append("  ret")
    out.append("")

    out.append("__fd_write:")
    out.append("  push rbp")
    out.append("  mov rbp, rsp")
    out.append("  push rbx")
    out.append("  push r12")
    out.append("  push r13")
    out.append("  push r14")
    out.append("  mov r12d, edi")
    out.append("  mov r13d, esi")
    out.append("  mov r14d, ecx")
    out.append("  xor ebx, ebx")
    out.append("  xor r10d, r10d")
    out.append(".L_fdw_loop:")
    out.append("  cmp r10d, edx")
    out.append("  jge .L_fdw_done")
    out.append("  lea r11, [rip+__coatl_mem]")
    out.append("  mov eax, r10d")
    out.append("  imul eax, 8")
    out.append("  add eax, r13d")
    out.append("  cdqe")
    out.append("  mov ecx, dword ptr [r11+rax]")
    out.append("  mov r8d, dword ptr [r11+rax+4]")
    out.append("  mov eax, ecx")
    out.append("  lea rsi, [r11+rax]")
    out.append("  mov edi, r12d")
    out.append("  mov edx, r8d")
    out.append("  mov eax, 1")
    out.append("  syscall")
    out.append("  test eax, eax")
    out.append("  js .L_fdw_err")
    out.append("  add ebx, eax")
    out.append("  inc r10d")
    out.append("  jmp .L_fdw_loop")
    out.append(".L_fdw_done:")
    out.append("  mov edi, r14d")
    out.append("  mov esi, ebx")
    out.append("  call __mem_store")
    out.append("  xor eax, eax")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  pop rbx")
    out.append("  leave")
    out.append("  ret")
    out.append(".L_fdw_err:")
    out.append("  neg eax")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  pop rbx")
    out.append("  leave")
    out.append("  ret")
    out.append("")

    out.append("__fd_read:")
    out.append("  push rbp")
    out.append("  mov rbp, rsp")
    out.append("  push rbx")
    out.append("  push r12")
    out.append("  push r13")
    out.append("  push r14")
    out.append("  mov r12d, edi")
    out.append("  mov r13d, esi")
    out.append("  mov r14d, ecx")
    out.append("  xor ebx, ebx")
    out.append("  xor r10d, r10d")
    out.append(".L_fdr_loop:")
    out.append("  cmp r10d, edx")
    out.append("  jge .L_fdr_done")
    out.append("  lea r11, [rip+__coatl_mem]")
    out.append("  mov eax, r10d")
    out.append("  imul eax, 8")
    out.append("  add eax, r13d")
    out.append("  cdqe")
    out.append("  mov ecx, dword ptr [r11+rax]")
    out.append("  mov r8d, dword ptr [r11+rax+4]")
    out.append("  mov eax, ecx")
    out.append("  lea rsi, [r11+rax]")
    out.append("  mov edi, r12d")
    out.append("  mov edx, r8d")
    out.append("  mov eax, 0")
    out.append("  syscall")
    out.append("  test eax, eax")
    out.append("  js .L_fdr_err")
    out.append("  add ebx, eax")
    out.append("  cmp eax, r8d")
    out.append("  jl .L_fdr_done")
    out.append("  inc r10d")
    out.append("  jmp .L_fdr_loop")
    out.append(".L_fdr_done:")
    out.append("  mov edi, r14d")
    out.append("  mov esi, ebx")
    out.append("  call __mem_store")
    out.append("  xor eax, eax")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  pop rbx")
    out.append("  leave")
    out.append("  ret")
    out.append(".L_fdr_err:")
    out.append("  neg eax")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  pop rbx")
    out.append("  leave")
    out.append("  ret")
    out.append("")

    out.append("__fd_close:")
    out.append("  mov eax, 3")
    out.append("  mov edi, edi")
    out.append("  syscall")
    out.append("  test eax, eax")
    out.append("  js .L_fdc_err")
    out.append("  xor eax, eax")
    out.append("  ret")
    out.append(".L_fdc_err:")
    out.append("  neg eax")
    out.append("  ret")
    out.append("")

    out.append("__path_open:")
    out.append("  push rbp")
    out.append("  mov rbp, rsp")
    out.append("  push r12")
    out.append("  push r13")
    out.append("  push r14")
    out.append("  sub rsp, 4096")
    out.append("  cmp ecx, 0")
    out.append("  jl .L_po_inval")
    out.append("  cmp ecx, 4095")
    out.append("  jg .L_po_inval")
    out.append("  mov r12d, edi")
    out.append("  mov r13d, r8d")
    out.append("  mov r14d, dword ptr [rbp+32]")
    out.append("  lea r11, [rsp]")
    out.append("  lea r10, [rip+__coatl_mem]")
    out.append("  mov eax, edx")
    out.append("  cdqe")
    out.append("  lea r10, [r10+rax]")
    out.append("  mov edx, ecx")
    out.append("  xor eax, eax")
    out.append(".L_po_copy_loop:")
    out.append("  cmp eax, edx")
    out.append("  jge .L_po_copy_done")
    out.append("  mov bl, byte ptr [r10+rax]")
    out.append("  mov byte ptr [r11+rax], bl")
    out.append("  inc eax")
    out.append("  jmp .L_po_copy_loop")
    out.append(".L_po_copy_done:")
    out.append("  mov byte ptr [r11+rdx], 0")
    out.append("  mov edi, r12d")
    out.append("  cmp edi, 3")
    out.append("  jne .L_po_dirfd_ok")
    out.append("  mov edi, -100")
    out.append(".L_po_dirfd_ok:")
    out.append("  mov esi, 0")
    out.append("  test r13d, 1")
    out.append("  jz .L_po_flags_done")
    out.append("  mov esi, 577")
    out.append(".L_po_flags_done:")
    out.append("  mov r10d, 420")
    out.append("  mov edx, esi")
    out.append("  mov rsi, r11")
    out.append("  mov eax, 257")
    out.append("  syscall")
    out.append("  test eax, eax")
    out.append("  js .L_po_err")
    out.append("  mov edi, r14d")
    out.append("  mov esi, eax")
    out.append("  call __mem_store")
    out.append("  xor eax, eax")
    out.append("  add rsp, 4096")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  leave")
    out.append("  ret")
    out.append(".L_po_inval:")
    out.append("  mov eax, 22")
    out.append("  add rsp, 4096")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  leave")
    out.append("  ret")
    out.append(".L_po_err:")
    out.append("  neg eax")
    out.append("  add rsp, 4096")
    out.append("  pop r14")
    out.append("  pop r13")
    out.append("  pop r12")
    out.append("  leave")
    out.append("  ret")
    out.append("")

    for name, params, block in parsed:
        fn = FnEmitter(name, params, block, string_addrs, fn_names)
        out.extend(fn.emit_function())

    out.append(".globl coatl_start")
    out.append("coatl_start:")
    out.append("  call main")
    out.append("  mov edi, eax")
    out.append("  mov eax, 60")
    out.append("  syscall")
    out.append("")

    return "\n".join(out) + "\n"


def lower_ir_to_asm(ir_path: Path, out_path: Path) -> None:
    src = ir_path.read_text()
    root = parse_sexpr(tokenize(src))
    out_path.write_text(lower_ir_to_asm_text(root))


def main() -> int:
    ap = argparse.ArgumentParser(description="Lower coatl_ir v0 to x86_64 assembly (IR-based path, no C compiler)")
    ap.add_argument("input", help="input .ir file")
    ap.add_argument("-o", "--output", required=True, help="output .s file")
    args = ap.parse_args()
    lower_ir_to_asm(Path(args.input), Path(args.output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
