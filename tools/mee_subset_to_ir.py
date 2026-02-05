#!/usr/bin/env python3
import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


class ParseError(Exception):
    pass


@dataclass
class Tok:
    kind: str
    text: str


def tokenize(src: str) -> List[Tok]:
    toks: List[Tok] = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c.isspace():
            i += 1
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            i += 2
            while i < n and src[i] != '\n':
                i += 1
            continue
        if src.startswith('->', i):
            toks.append(Tok('sym', '->'))
            i += 2
            continue
        if src.startswith('<=', i) or src.startswith('>=', i) or src.startswith('==', i) or src.startswith('!=', i) or src.startswith('&&', i) or src.startswith('||', i):
            toks.append(Tok('sym', src[i:i + 2]))
            i += 2
            continue
        if c in '(){}:,;=+-*/<>!.':
            toks.append(Tok('sym', c))
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
                raise ParseError('unterminated string literal')
            toks.append(Tok('str', src[i:j + 1]))
            i = j + 1
            continue
        m_num = re.match(r'[0-9]+', src[i:])
        if m_num:
            txt = m_num.group(0)
            toks.append(Tok('num', txt))
            i += len(txt)
            continue
        m_ident = re.match(r'[A-Za-z_][A-Za-z0-9_]*', src[i:])
        if m_ident:
            txt = m_ident.group(0)
            toks.append(Tok('ident', txt))
            i += len(txt)
            continue
        raise ParseError(f'unexpected character: {c!r}')
    toks.append(Tok('eof', ''))
    return toks


class Parser:
    def __init__(self, toks: List[Tok]):
        self.toks = toks
        self.i = 0
        self.struct_fields: dict[str, List[str]] = {}
        self.local_structs: dict[str, str] = {}
        self.param_structs: dict[str, str] = {}
        self.fn_return_struct: dict[str, str] = {}

    def peek(self) -> Tok:
        return self.toks[self.i]

    def next(self) -> Tok:
        t = self.toks[self.i]
        self.i += 1
        return t

    def expect(self, kind: str, text: Optional[str] = None) -> Tok:
        t = self.next()
        if t.kind != kind:
            raise ParseError(f'expected {kind}, got {t.kind}:{t.text}')
        if text is not None and t.text != text:
            raise ParseError(f'expected {text}, got {t.text}')
        return t

    def expect_ident(self, txt: Optional[str] = None) -> Tok:
        t = self.expect('ident')
        if txt is not None and t.text != txt:
            raise ParseError(f'expected identifier {txt}, got {t.text}')
        return t

    def parse_program_ir(self) -> str:
        fns: List[str] = []
        saw_main = False
        while self.peek().kind != 'eof':
            if self.peek().kind == 'ident' and self.peek().text == 'struct':
                self.parse_struct_decl()
                continue
            fn_name, fn_ir = self.parse_fn_ir()
            if fn_name == 'main':
                saw_main = True
            fns.append(fn_ir)
        if not saw_main:
            raise ParseError('expected fn main')
        return '(mee_ir v0\n  (structs)\n  (functions\n' + ''.join(fns) + '  )\n)\n'

    def parse_struct_decl(self) -> None:
        self.expect_ident('struct')
        name = self.expect_ident().text
        self.expect('sym', '{')
        fields: List[str] = []
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            fld = self.expect_ident().text
            self.expect('sym', ':')
            self.expect_ident('i32')
            fields.append(fld)
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
        self.expect('sym', '}')
        self.struct_fields[name] = fields

    def parse_fn_ir(self) -> Tuple[str, str]:
        self.local_structs = {}
        self.param_structs = {}
        self.expect_ident('fn')
        name = self.expect_ident().text
        self.expect('sym', '(')
        params, params_ir = self.parse_params_ir()
        self.expect('sym', ')')
        self.expect('sym', '->')
        ret_ty = self.expect_ident().text
        if ret_ty != 'i32' and ret_ty not in self.struct_fields:
            raise ParseError(f'unsupported function return type: {ret_ty}')
        if ret_ty in self.struct_fields:
            self.fn_return_struct[name] = ret_ty
            return name, self.parse_struct_return_fn_irs(name, params, params_ir, ret_ty)
        block = self.parse_block_ir(ret_struct_ty=None)
        fn_ir = (
            f'    (fn {name}\n'
            f'{params_ir}'
            '      (ret i32)\n'
            f'{block}'
            '    )\n'
        )
        return name, fn_ir

    def parse_params_ir(self) -> Tuple[List[str], str]:
        if self.peek().kind == 'sym' and self.peek().text == ')':
            return [], '      (params)\n'
        params: List[str] = []
        while True:
            name = self.expect_ident().text
            self.expect('sym', ':')
            ty = self.expect_ident().text
            if ty == 'i32':
                params.append(name)
            elif ty in self.struct_fields:
                self.param_structs[name] = ty
                for fld in self.struct_fields[ty]:
                    params.append(f'{name}__{fld}')
            else:
                raise ParseError(f'unsupported parameter type: {ty}')
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
                continue
            break
        body = ''.join(f'        (param {p} i32)\n' for p in params)
        return params, '      (params\n' + body + '      )\n'

    def parse_block_ir(self, ret_struct_ty: Optional[str]) -> str:
        self.expect('sym', '{')
        stmts: List[str] = []
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            stmts.append(self.parse_stmt_ir(ret_struct_ty))
        self.expect('sym', '}')
        if not stmts:
            return '      (block)\n'
        return '      (block\n' + ''.join(stmts) + '      )\n'

    def parse_stmt_ir(self, ret_struct_ty: Optional[str]) -> str:
        t = self.peek()
        if t.kind == 'ident' and t.text == 'let':
            self.next()
            name = self.expect_ident().text
            self.expect('sym', ':')
            ty = self.expect_ident().text
            self.expect('sym', '=')
            if ty in self.struct_fields:
                stmt = self.parse_struct_init_stmt_ir(name, ty)
                self.expect('sym', ';')
                return stmt
            if ty != 'i32':
                raise ParseError(f'unsupported let type: {ty}')
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            return f'        (let {name} i32\n{expr}        )\n'
        if t.kind == 'ident' and t.text == 'return':
            self.next()
            if ret_struct_ty is not None:
                raise ParseError(f'unsupported return in struct-return function body: expected {ret_struct_ty} literal return only')
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            return f'        (return\n{expr}        )\n'
        if t.kind == 'ident' and t.text == 'if':
            self.next()
            self.expect('sym', '(')
            cond = self.parse_expr_ir()
            self.expect('sym', ')')
            then_block = self.parse_block_ir(ret_struct_ty)
            if self.peek().kind == 'ident' and self.peek().text == 'else':
                self.next()
                else_block = self.parse_block_ir(ret_struct_ty)
                return f'        (if\n{cond}{then_block}          (else\n{else_block}          )\n        )\n'
            return f'        (if\n{cond}{then_block}        )\n'
        if t.kind == 'ident' and t.text == 'while':
            self.next()
            self.expect('sym', '(')
            cond = self.parse_expr_ir()
            self.expect('sym', ')')
            body = self.parse_block_ir(ret_struct_ty)
            return f'        (while\n{cond}{body}        )\n'
        if t.kind == 'ident':
            t1 = self.toks[self.i + 1]
            if t1.kind == 'sym' and t1.text == '.':
                name = self.next().text
                self.expect('sym', '.')
                fld = self.expect_ident().text
                self.expect('sym', '=')
                fields = self.struct_var_fields(name)
                if fields is None:
                    raise ParseError(f'field assignment on non-struct value: {name}')
                if fld not in fields:
                    raise ParseError(f'unknown field {fld} on struct value: {name}')
                expr = self.parse_expr_ir()
                self.expect('sym', ';')
                return f'        (assign {name}__{fld}\n{expr}        )\n'
            if t1.kind == 'sym' and t1.text == '=':
                name = self.next().text
                if name in self.local_structs or name in self.param_structs:
                    raise ParseError('assigning entire struct values is not supported in subset frontend')
                self.expect('sym', '=')
                expr = self.parse_expr_ir()
                self.expect('sym', ';')
                return f'        (assign {name}\n{expr}        )\n'
        expr = self.parse_expr_ir()
        self.expect('sym', ';')
        return f'        (expr\n{expr}        )\n'

    def parse_struct_init_stmt_ir(self, name: str, ty: str) -> str:
        ctor = self.expect_ident().text
        if self.peek().kind == 'sym' and self.peek().text == '(':
            return self.parse_struct_call_init_stmt_ir(name, ty, ctor)
        if ctor != ty:
            raise ParseError(f'expected struct constructor {ty}, got {ctor}')
        self.expect('sym', '{')
        vals: dict[str, str] = {}
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            fld = self.expect_ident().text
            self.expect('sym', ':')
            vals[fld] = self.parse_expr_ir()
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
        self.expect('sym', '}')
        fields = self.struct_fields[ty]
        for fld in vals.keys():
            if fld not in fields:
                raise ParseError(f'unknown field {fld} for struct {ty}')
        for fld in fields:
            if fld not in vals:
                raise ParseError(f'missing field {fld} for struct {ty}')
        self.local_structs[name] = ty
        out = ''
        for fld in fields:
            out += f'        (let {name}__{fld} i32\n{vals[fld]}        )\n'
        return out

    def parse_struct_call_init_stmt_ir(self, name: str, ty: str, fn_name: str) -> str:
        if fn_name not in self.fn_return_struct or self.fn_return_struct[fn_name] != ty:
            raise ParseError(f'unsupported struct-producing call for {ty}: {fn_name}')
        self.expect('sym', '(')
        args = self.parse_call_args_ir()
        self.expect('sym', ')')
        self.local_structs[name] = ty
        out = ''
        for fld in self.struct_fields[ty]:
            out += f'        (let {name}__{fld} i32\n'
            out += f'          (call {fn_name}__ret__{fld}\n'
            out += args
            out += '          )\n'
            out += '        )\n'
        return out

    def parse_call_args_ir(self) -> str:
        args: List[str] = []
        if not (self.peek().kind == 'sym' and self.peek().text == ')'):
            while True:
                if self.peek().kind == 'ident':
                    arg_name = self.peek().text
                    arg_fields = self.struct_var_fields(arg_name)
                    next_tok = self.toks[self.i + 1]
                    if arg_fields is not None and next_tok.kind == 'sym' and next_tok.text in (',', ')'):
                        self.next()
                        for fld in arg_fields:
                            args.append(f'          (ident {arg_name}__{fld})\n')
                    else:
                        args.append(self.parse_expr_ir())
                else:
                    args.append(self.parse_expr_ir())
                if self.peek().kind == 'sym' and self.peek().text == ',':
                    self.next()
                    continue
                break
        return ''.join(args)

    def parse_struct_return_literal(self, ty: str) -> dict[str, str]:
        ctor = self.expect_ident().text
        if ctor != ty:
            raise ParseError(f'expected struct constructor {ty}, got {ctor}')
        self.expect('sym', '{')
        vals: dict[str, str] = {}
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            fld = self.expect_ident().text
            self.expect('sym', ':')
            vals[fld] = self.parse_expr_ir()
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
        self.expect('sym', '}')
        for fld in vals.keys():
            if fld not in self.struct_fields[ty]:
                raise ParseError(f'unknown field {fld} for struct {ty}')
        for fld in self.struct_fields[ty]:
            if fld not in vals:
                raise ParseError(f'missing field {fld} for struct {ty}')
        return vals

    def parse_struct_return_fn_irs(self, name: str, params: List[str], params_ir: str, ret_ty: str) -> str:
        self.expect('sym', '{')
        self.expect_ident('return')
        ret_vals = self.parse_struct_return_literal(ret_ty)
        self.expect('sym', ';')
        self.expect('sym', '}')
        out = ''
        param_sig = ''.join(f'        (param {p} i32)\n' for p in params)
        params_section = '      (params)\n' if not params else ('      (params\n' + param_sig + '      )\n')
        for fld in self.struct_fields[ret_ty]:
            out += f'    (fn {name}__ret__{fld}\n'
            out += params_section
            out += '      (ret i32)\n'
            out += '      (block\n'
            out += '        (return\n'
            out += ret_vals[fld]
            out += '        )\n'
            out += '      )\n'
            out += '    )\n'
        return out

    def struct_var_fields(self, name: str) -> Optional[List[str]]:
        if name in self.local_structs:
            return self.struct_fields[self.local_structs[name]]
        if name in self.param_structs:
            return self.struct_fields[self.param_structs[name]]
        return None

    def parse_expr_ir(self) -> str:
        left = self.parse_or_ir()
        return left

    def parse_or_ir(self) -> str:
        left = self.parse_and_ir()
        while self.peek().kind == 'sym' and self.peek().text == '||':
            self.next()
            right = self.parse_and_ir()
            left = (
                '          (binary or\n'
                f'{left}'
                f'{right}'
                '          )\n'
            )
        return left

    def parse_and_ir(self) -> str:
        left = self.parse_cmp_ir()
        while self.peek().kind == 'sym' and self.peek().text == '&&':
            self.next()
            right = self.parse_cmp_ir()
            left = (
                '          (binary and\n'
                f'{left}'
                f'{right}'
                '          )\n'
            )
        return left

    def parse_cmp_ir(self) -> str:
        left = self.parse_add_ir()
        while self.peek().kind == 'sym' and self.peek().text in ('<', '>', '<=', '>=', '==', '!='):
            op = self.next().text
            right = self.parse_add_ir()
            op_name = {
                '<': 'lt',
                '>': 'gt',
                '<=': 'le',
                '>=': 'ge',
                '==': 'eq',
                '!=': 'ne',
            }[op]
            left = (
                f'          (binary {op_name}\n'
                f'{left}'
                f'{right}'
                '          )\n'
            )
        return left

    def parse_add_ir(self) -> str:
        left = self.parse_mul_ir()
        while self.peek().kind == 'sym' and self.peek().text in ('+', '-'):
            op = self.next().text
            right = self.parse_mul_ir()
            op_name = 'add' if op == '+' else 'sub'
            left = (
                f'          (binary {op_name}\n'
                f'{left}'
                f'{right}'
                '          )\n'
            )
        return left

    def parse_mul_ir(self) -> str:
        left = self.parse_term_ir()
        while self.peek().kind == 'sym' and self.peek().text in ('*', '/'):
            op = self.next().text
            right = self.parse_term_ir()
            op_name = 'mul' if op == '*' else 'div'
            left = (
                f'          (binary {op_name}\n'
                f'{left}'
                f'{right}'
                '          )\n'
            )
        return left

    def parse_term_ir(self) -> str:
        t = self.peek()
        if t.kind == 'num':
            self.next()
            return f'          (int {t.text})\n'
        if t.kind == 'str':
            self.next()
            return f'          (string {t.text})\n'
        if t.kind == 'ident':
            name = self.next().text
            if name == 'true':
                return '          (bool 1)\n'
            if name == 'false':
                return '          (bool 0)\n'
            if self.peek().kind == 'sym' and self.peek().text == '.':
                self.next()
                fld = self.expect_ident().text
                fields = self.struct_var_fields(name)
                if fields is None:
                    raise ParseError(f'field access on non-struct value: {name}')
                if fld not in fields:
                    raise ParseError(f'unknown field {fld} on struct value: {name}')
                return f'          (ident {name}__{fld})\n'
            if self.peek().kind == 'sym' and self.peek().text == '(':
                self.next()
                if name in self.fn_return_struct:
                    raise ParseError(f'struct-return call must be used in struct let initialization: {name}')
                inner = self.parse_call_args_ir()
                self.expect('sym', ')')
                if not inner:
                    return f'          (call {name})\n'
                return f'          (call {name}\n{inner}          )\n'
            return f'          (ident {name})\n'
        if t.kind == 'sym' and t.text == '(':
            self.next()
            e = self.parse_expr_ir()
            self.expect('sym', ')')
            return e
        if t.kind == 'sym' and t.text == '!':
            self.next()
            e = self.parse_term_ir()
            return (
                '          (binary eq\n'
                f'{e}'
                '          (int 0)\n'
                '          )\n'
            )
        raise ParseError(f'unexpected token in expression: {t.kind}:{t.text}')


def main() -> int:
    ap = argparse.ArgumentParser(description='Compile Mee subset to mee_ir v0')
    ap.add_argument('input', help='input .mee file')
    ap.add_argument('-o', '--output', required=True, help='output .ir file')
    args = ap.parse_args()

    src = Path(args.input).read_text()
    toks = tokenize(src)
    p = Parser(toks)
    ir = p.parse_program_ir()
    Path(args.output).write_text(ir)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
