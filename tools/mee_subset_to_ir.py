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
        if c in '(){}:,;=+-*/':
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
            fn_name, fn_ir = self.parse_fn_ir()
            if fn_name == 'main':
                saw_main = True
            fns.append(fn_ir)
        if not saw_main:
            raise ParseError('expected fn main')
        return '(mee_ir v0\n  (structs)\n  (functions\n' + ''.join(fns) + '  )\n)\n'

    def parse_fn_ir(self) -> Tuple[str, str]:
        self.expect_ident('fn')
        name = self.expect_ident().text
        self.expect('sym', '(')
        params_ir = self.parse_params_ir()
        self.expect('sym', ')')
        self.expect('sym', '->')
        self.expect_ident('i32')
        block = self.parse_block_ir()
        fn_ir = (
            f'    (fn {name}\n'
            f'{params_ir}'
            '      (ret i32)\n'
            f'{block}'
            '    )\n'
        )
        return name, fn_ir

    def parse_params_ir(self) -> str:
        if self.peek().kind == 'sym' and self.peek().text == ')':
            return '      (params)\n'
        params: List[str] = []
        while True:
            name = self.expect_ident().text
            self.expect('sym', ':')
            self.expect_ident('i32')
            params.append(name)
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
                continue
            break
        body = ''.join(f'        (param {p} i32)\n' for p in params)
        return '      (params\n' + body + '      )\n'

    def parse_block_ir(self) -> str:
        self.expect('sym', '{')
        stmts: List[str] = []
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            stmts.append(self.parse_stmt_ir())
        self.expect('sym', '}')
        if not stmts:
            return '      (block)\n'
        return '      (block\n' + ''.join(stmts) + '      )\n'

    def parse_stmt_ir(self) -> str:
        t = self.peek()
        if t.kind == 'ident' and t.text == 'let':
            self.next()
            name = self.expect_ident().text
            self.expect('sym', ':')
            self.expect_ident('i32')
            self.expect('sym', '=')
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            return f'        (let {name} i32\n{expr}        )\n'
        if t.kind == 'ident' and t.text == 'return':
            self.next()
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            return f'        (return\n{expr}        )\n'
        if t.kind == 'ident':
            t1 = self.toks[self.i + 1]
            if t1.kind == 'sym' and t1.text == '=':
                name = self.next().text
                self.expect('sym', '=')
                expr = self.parse_expr_ir()
                self.expect('sym', ';')
                return f'        (assign {name}\n{expr}        )\n'
        expr = self.parse_expr_ir()
        self.expect('sym', ';')
        return f'        (expr\n{expr}        )\n'

    def parse_expr_ir(self) -> str:
        left = self.parse_add_ir()
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
            if self.peek().kind == 'sym' and self.peek().text == '(':
                self.next()
                args: List[str] = []
                if not (self.peek().kind == 'sym' and self.peek().text == ')'):
                    args.append(self.parse_expr_ir())
                    while self.peek().kind == 'sym' and self.peek().text == ',':
                        self.next()
                        args.append(self.parse_expr_ir())
                self.expect('sym', ')')
                if not args:
                    return f'          (call {name})\n'
                inner = ''.join(args)
                return f'          (call {name}\n{inner}          )\n'
            return f'          (ident {name})\n'
        if t.kind == 'sym' and t.text == '(':
            self.next()
            e = self.parse_expr_ir()
            self.expect('sym', ')')
            return e
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
