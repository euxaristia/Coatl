#!/usr/bin/env python3
import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import List, Union

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

    def local_index(self, name: str) -> int:
        if name not in self.locals:
            raise LowerError(f"unknown local: {name}")
        return self.locals.index(name)


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
    if tag == "binary":
        op = as_atom(e[1])
        op_wat = WAT_OPS.get(op)
        if not op_wat:
            raise LowerError(f"unsupported binary op: {op}")
        emit_expr(e[2], ctx, out)
        emit_expr(e[3], ctx, out)
        out.append(f"    {op_wat}")
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


def lower_main_fn(main_fn: List[Node]) -> str:
    # (fn main (params) (ret i32) (block ...))
    if len(main_fn) != 5:
        raise LowerError("main function shape not supported")
    if as_atom(main_fn[0]) != "fn" or as_atom(main_fn[1]) != "main":
        raise LowerError("only main function is supported")
    params = as_list(main_fn[2])
    if len(params) != 1 or as_atom(params[0]) != "params":
        raise LowerError("expected empty params")
    ret = as_list(main_fn[3])
    if len(ret) != 2 or as_atom(ret[0]) != "ret" or as_atom(ret[1]) != "i32":
        raise LowerError("only (ret i32) supported")
    block = as_list(main_fn[4])

    locals_ = collect_locals(block)
    ctx = Ctx(locals_)

    body: List[str] = []
    for stmt in block[1:]:
        emit_stmt(stmt, ctx, body)

    lines: List[str] = []
    lines.append("(module")
    lines.append("  (func $main (result i32)")
    for _ in locals_:
        lines.append("    (local i32)")
    lines.extend(body)
    lines.append("  )")
    lines.append("  (export \"main\" (func $main))")
    lines.append(")")
    return "\n".join(lines) + "\n"


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

    fns = [as_list(f) for f in functions[1:]]
    mains = [f for f in fns if len(f) >= 2 and as_atom(f[0]) == "fn" and as_atom(f[1]) == "main"]
    if len(mains) != 1:
        raise LowerError("expected exactly one main function")
    return lower_main_fn(mains[0])


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
