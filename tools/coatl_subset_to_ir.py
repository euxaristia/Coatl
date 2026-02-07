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
        if c in '(){}[]:,;=+-*/<>!.':
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
        m_num = re.match(r'[0-9]+(\.[0-9]+)?', src[i:])
        if m_num:
            txt = m_num.group(0)
            # Check for type suffix: i64, f32, f64
            rest = src[i + len(txt):]
            suffix_m = re.match(r'(i64|f32|f64)', rest)
            if suffix_m:
                suffix = suffix_m.group(0)
                toks.append(Tok('num', txt))
                toks.append(Tok('suffix', suffix))
                i += len(txt) + len(suffix)
            else:
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
    SCALAR_TYPES = {'i32', 'bool', 'i64', 'f32', 'f64', 'str'}

    def __init__(self, toks: List[Tok]):
        self.toks = toks
        self.i = 0
        self.struct_fields: dict[str, List[str]] = {}
        self.local_structs: dict[str, str] = {}
        self.param_structs: dict[str, str] = {}
        self.fn_return_struct: dict[str, str] = {}
        self.local_types: dict[str, str] = {}
        self.param_types: dict[str, str] = {}
        self.fn_return_type: str = 'i32'

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
        return '(coatl_ir v1\n  (structs)\n  (functions\n' + ''.join(fns) + '  )\n)\n'

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
        self.local_types = {}
        self.param_types = {}
        self.expect_ident('fn')
        name = self.expect_ident().text
        self.expect('sym', '(')
        params, params_ir = self.parse_params_ir()
        self.expect('sym', ')')
        self.expect('sym', '->')
        ret_ty = self.parse_type()
        self.fn_return_type = ret_ty
        if ret_ty not in self.SCALAR_TYPES and ret_ty not in self.struct_fields:
            raise ParseError(f'unsupported function return type: {ret_ty}')
        if ret_ty in self.struct_fields:
            self.fn_return_struct[name] = ret_ty
            return name, self.parse_struct_return_fn_irs(name, params, ret_ty)
        block = self.parse_block_ir(ret_struct_ty=None, ret_struct_field=None)
        fn_ir = (
            f'    (fn {name}\n'
            f'{params_ir}'
            f'      (ret {ret_ty})\n'
            f'{block}'
            '    )\n'
        )
        return name, fn_ir

    def parse_type(self) -> str:
        """Parse a type: i32, bool, i64, f32, f64, str, [T; N], or struct name."""
        if self.peek().kind == 'sym' and self.peek().text == '[':
            self.next()  # consume '['
            elem_ty = self.expect_ident().text
            if elem_ty not in self.SCALAR_TYPES:
                raise ParseError(f'unsupported array element type: {elem_ty}')
            self.expect('sym', ';')
            size_tok = self.expect('num')
            self.expect('sym', ']')
            return f'[{elem_ty}; {size_tok.text}]'
        return self.expect_ident().text

    def parse_params_ir(self) -> Tuple[List[str], str]:
        if self.peek().kind == 'sym' and self.peek().text == ')':
            return [], '      (params)\n'
        params: List[str] = []
        param_types_list: List[Tuple[str, str]] = []
        while True:
            name = self.expect_ident().text
            self.expect('sym', ':')
            ty = self.parse_type()
            if ty in self.SCALAR_TYPES:
                params.append(name)
                param_types_list.append((name, ty))
                self.param_types[name] = ty
            elif ty in self.struct_fields:
                self.param_structs[name] = ty
                for fld in self.struct_fields[ty]:
                    params.append(f'{name}__{fld}')
                    param_types_list.append((f'{name}__{fld}', 'i32'))
            elif ty.startswith('['):
                params.append(name)
                param_types_list.append((name, 'i32'))  # arrays are ptrs
                self.param_types[name] = ty
            else:
                raise ParseError(f'unsupported parameter type: {ty}')
            if self.peek().kind == 'sym' and self.peek().text == ',':
                self.next()
                continue
            break
        body = ''.join(f'        (param {p} {ty})\n' for p, ty in param_types_list)
        return params, '      (params\n' + body + '      )\n'

    def parse_block_ir(self, ret_struct_ty: Optional[str], ret_struct_field: Optional[str]) -> str:
        self.expect('sym', '{')
        stmts: List[str] = []
        while not (self.peek().kind == 'sym' and self.peek().text == '}'):
            stmts.append(self.parse_stmt_ir(ret_struct_ty, ret_struct_field))
        self.expect('sym', '}')
        if not stmts:
            return '      (block)\n'
        return '      (block\n' + ''.join(stmts) + '      )\n'

    def parse_stmt_ir(self, ret_struct_ty: Optional[str], ret_struct_field: Optional[str]) -> str:
        t = self.peek()
        if t.kind == 'ident' and t.text == 'let':
            self.next()
            name = self.expect_ident().text
            self.expect('sym', ':')
            ty = self.parse_type()
            self.expect('sym', '=')
            if ty in self.struct_fields:
                stmt = self.parse_struct_init_stmt_ir(name, ty)
                self.expect('sym', ';')
                return stmt
            if ty.startswith('['):
                # Array type: parse array literal [val; N] or allocator
                self.local_types[name] = ty
                expr = self.parse_array_init_ir(name, ty)
                self.expect('sym', ';')
                return expr
            if ty not in self.SCALAR_TYPES:
                raise ParseError(f'unsupported let type: {ty}')
            self.local_types[name] = ty
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            # For str type, replace (string ...) with (string_typed ...)
            if ty == 'str':
                expr = expr.replace('(string ', '(string_typed ', 1)
            return f'        (let {name} {ty}\n{expr}        )\n'
        if t.kind == 'ident' and t.text == 'return':
            self.next()
            if ret_struct_ty is not None:
                if ret_struct_field is None:
                    raise ParseError('internal error: missing struct return field context')
                ret_vals = self.parse_struct_return_literal(ret_struct_ty)
                self.expect('sym', ';')
                return f'        (return\n{ret_vals[ret_struct_field]}        )\n'
            expr = self.parse_expr_ir()
            self.expect('sym', ';')
            return f'        (return\n{expr}        )\n'
        if t.kind == 'ident' and t.text == 'if':
            self.next()
            self.expect('sym', '(')
            cond = self.parse_expr_ir()
            self.expect('sym', ')')
            then_block = self.parse_block_ir(ret_struct_ty, ret_struct_field)
            if self.peek().kind == 'ident' and self.peek().text == 'else':
                self.next()
                else_block = self.parse_block_ir(ret_struct_ty, ret_struct_field)
                return f'        (if\n{cond}{then_block}          (else\n{else_block}          )\n        )\n'
            return f'        (if\n{cond}{then_block}        )\n'
        if t.kind == 'ident' and t.text == 'while':
            self.next()
            self.expect('sym', '(')
            cond = self.parse_expr_ir()
            self.expect('sym', ')')
            body = self.parse_block_ir(ret_struct_ty, ret_struct_field)
            return f'        (while\n{cond}{body}        )\n'
        if t.kind == 'ident':
            t1 = self.toks[self.i + 1]
            if t1.kind == 'sym' and t1.text == '[':
                # Array index assignment: arr[i] = expr;
                name = self.next().text
                self.expect('sym', '[')
                idx_ir = self.parse_expr_ir()
                self.expect('sym', ']')
                self.expect('sym', '=')
                val_ir = self.parse_expr_ir()
                self.expect('sym', ';')
                arr_ty = self.var_type(name)
                import re as _re
                m = _re.match(r'\[(\w+);\s*(\d+)\]', arr_ty)
                elem_ty = m.group(1) if m else 'i32'
                return (
                    f'        (expr\n'
                    f'          (array_set {elem_ty}\n'
                    f'            (ident {name})\n'
                    f'{idx_ir}'
                    f'{val_ir}'
                    f'          )\n'
                    f'        )\n'
                )
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
                    next_tok = self.toks[self.i + 1]
                    if next_tok.kind == 'sym' and next_tok.text == '(' and arg_name in self.fn_return_struct:
                        self.next()
                        self.expect('sym', '(')
                        call_args = self.parse_call_args_ir()
                        self.expect('sym', ')')
                        for fld in self.struct_fields[self.fn_return_struct[arg_name]]:
                            args.append(f'          (call {arg_name}__ret__{fld}\n')
                            args.append(call_args)
                            args.append('          )\n')
                        if self.peek().kind == 'sym' and self.peek().text == ',':
                            self.next()
                            continue
                        break
                    arg_fields = self.struct_var_fields(arg_name)
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

    def parse_block_range_ir(self, stop_index: int, ret_struct_ty: Optional[str], ret_struct_field: Optional[str]) -> str:
        stmts: List[str] = []
        while self.i < stop_index:
            stmts.append(self.parse_stmt_ir(ret_struct_ty, ret_struct_field))
        if self.i != stop_index:
            raise ParseError('invalid block range parse state')
        if not stmts:
            return '      (block)\n'
        return '      (block\n' + ''.join(stmts) + '      )\n'

    def parse_struct_return_fn_irs(self, name: str, params: List[str], ret_ty: str) -> str:
        self.expect('sym', '{')
        body_start = self.i
        depth = 1
        j = self.i
        while j < len(self.toks):
            t = self.toks[j]
            if t.kind == 'sym' and t.text == '{':
                depth += 1
            elif t.kind == 'sym' and t.text == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        if depth != 0:
            raise ParseError('unterminated function block')
        body_end = j
        self.i = body_end + 1

        out = ''
        param_sig = ''.join(f'        (param {p} i32)\n' for p in params)
        params_section = '      (params)\n' if not params else ('      (params\n' + param_sig + '      )\n')
        for fld in self.struct_fields[ret_ty]:
            self.local_structs = {}
            self.i = body_start
            block = self.parse_block_range_ir(body_end, ret_ty, fld)
            out += f'    (fn {name}__ret__{fld}\n'
            out += params_section
            out += '      (ret i32)\n'
            out += block
            out += '    )\n'
        self.i = body_end + 1
        return out

    def parse_array_init_ir(self, name: str, ty: str) -> str:
        """Parse [val; N] array literal and emit array_alloc + array_set nodes."""
        # Parse: [elem_type; size] where ty is already parsed
        # Extract element type and size from ty string like "[i32; 4]"
        import re
        m = re.match(r'\[(\w+);\s*(\d+)\]', ty)
        if not m:
            raise ParseError(f'invalid array type: {ty}')
        elem_ty = m.group(1)
        arr_size = int(m.group(2))

        # Expect: [init_val; N]
        self.expect('sym', '[')
        init_expr = self.parse_expr_ir()
        self.expect('sym', ';')
        count_tok = self.expect('num')
        count = int(count_tok.text)
        self.expect('sym', ']')
        if count != arr_size:
            raise ParseError(f'array init size mismatch: type has {arr_size} but init has {count}')

        out = f'        (let {name} i32\n          (array_alloc {elem_ty} {arr_size})\n        )\n'
        for i in range(arr_size):
            out += f'        (expr\n          (array_set {elem_ty}\n            (ident {name})\n            (int {i})\n{init_expr}          )\n        )\n'
        return out

    def var_type(self, name: str) -> str:
        """Look up the type of a variable."""
        if name in self.local_types:
            return self.local_types[name]
        if name in self.param_types:
            return self.param_types[name]
        return 'i32'

    def struct_var_fields(self, name: str) -> Optional[List[str]]:
        if name in self.local_structs:
            return self.struct_fields[self.local_structs[name]]
        if name in self.param_structs:
            return self.struct_fields[self.param_structs[name]]
        return None

    def parse_expr_ir(self) -> str:
        ir, _ = self.parse_expr_typed()
        return ir

    def parse_expr_typed(self) -> Tuple[str, str]:
        """Parse an expression, returning (ir_text, type_str)."""
        return self.parse_or_typed()

    def parse_or_typed(self) -> Tuple[str, str]:
        left_ir, left_ty = self.parse_and_typed()
        while self.peek().kind == 'sym' and self.peek().text == '||':
            self.next()
            right_ir, right_ty = self.parse_and_typed()
            left_ir = (
                '          (binary or\n'
                f'{left_ir}'
                f'{right_ir}'
                '          )\n'
            )
            left_ty = 'i32'
        return left_ir, left_ty

    def parse_and_typed(self) -> Tuple[str, str]:
        left_ir, left_ty = self.parse_cmp_typed()
        while self.peek().kind == 'sym' and self.peek().text == '&&':
            self.next()
            right_ir, right_ty = self.parse_cmp_typed()
            left_ir = (
                '          (binary and\n'
                f'{left_ir}'
                f'{right_ir}'
                '          )\n'
            )
            left_ty = 'i32'
        return left_ir, left_ty

    def parse_cmp_typed(self) -> Tuple[str, str]:
        left_ir, left_ty = self.parse_add_typed()
        while self.peek().kind == 'sym' and self.peek().text in ('<', '>', '<=', '>=', '==', '!='):
            op = self.next().text
            right_ir, right_ty = self.parse_add_typed()
            op_name = {
                '<': 'lt', '>': 'gt', '<=': 'le', '>=': 'ge', '==': 'eq', '!=': 'ne',
            }[op]
            bin_ty = self._resolve_binop_type(left_ty, right_ty)
            if bin_ty != 'i32':
                left_ir = (
                    f'          (binary {op_name} {bin_ty}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            else:
                left_ir = (
                    f'          (binary {op_name}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            left_ty = 'i32'  # comparisons always return i32
        return left_ir, left_ty

    def parse_add_typed(self) -> Tuple[str, str]:
        left_ir, left_ty = self.parse_mul_typed()
        while self.peek().kind == 'sym' and self.peek().text in ('+', '-'):
            op = self.next().text
            right_ir, right_ty = self.parse_mul_typed()
            op_name = 'add' if op == '+' else 'sub'
            bin_ty = self._resolve_binop_type(left_ty, right_ty)
            if bin_ty != 'i32':
                left_ir = (
                    f'          (binary {op_name} {bin_ty}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            else:
                left_ir = (
                    f'          (binary {op_name}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            left_ty = bin_ty
        return left_ir, left_ty

    def parse_mul_typed(self) -> Tuple[str, str]:
        left_ir, left_ty = self.parse_term_typed()
        while self.peek().kind == 'sym' and self.peek().text in ('*', '/'):
            op = self.next().text
            right_ir, right_ty = self.parse_term_typed()
            op_name = 'mul' if op == '*' else 'div'
            bin_ty = self._resolve_binop_type(left_ty, right_ty)
            if bin_ty != 'i32':
                left_ir = (
                    f'          (binary {op_name} {bin_ty}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            else:
                left_ir = (
                    f'          (binary {op_name}\n'
                    f'{left_ir}'
                    f'{right_ir}'
                    '          )\n'
                )
            left_ty = bin_ty
        return left_ir, left_ty

    def _resolve_binop_type(self, left_ty: str, right_ty: str) -> str:
        """Determine the type for a binary operation from its operand types."""
        # If both are i32/bool, use i32 (the default, no annotation needed)
        if left_ty in ('i32', 'bool') and right_ty in ('i32', 'bool'):
            return 'i32'
        # If either is a non-i32 scalar, that wins
        for ty in (left_ty, right_ty):
            if ty in ('i64', 'f32', 'f64'):
                return ty
        return 'i32'

    def parse_term_typed(self) -> Tuple[str, str]:
        t = self.peek()
        if t.kind == 'num':
            self.next()
            # Check for type suffix
            if self.peek().kind == 'suffix':
                suffix = self.next().text
                if suffix == 'i64':
                    return f'          (int_i64 {t.text})\n', 'i64'
                elif suffix == 'f32':
                    return f'          (float_f32 {t.text})\n', 'f32'
                elif suffix == 'f64':
                    return f'          (float_f64 {t.text})\n', 'f64'
            # Plain float literal (has dot) defaults to f32
            if '.' in t.text:
                return f'          (float_f32 {t.text})\n', 'f32'
            return f'          (int {t.text})\n', 'i32'
        if t.kind == 'str':
            self.next()
            return f'          (string {t.text})\n', 'i32'
        if t.kind == 'ident':
            name = self.next().text
            if name == 'true':
                return '          (bool 1)\n', 'bool'
            if name == 'false':
                return '          (bool 0)\n', 'bool'
            if self.peek().kind == 'sym' and self.peek().text == '.':
                self.next()
                fld = self.expect_ident().text
                fields = self.struct_var_fields(name)
                if fields is None:
                    raise ParseError(f'field access on non-struct value: {name}')
                if fld not in fields:
                    raise ParseError(f'unknown field {fld} on struct value: {name}')
                return f'          (ident {name}__{fld})\n', 'i32'
            if self.peek().kind == 'sym' and self.peek().text == '[':
                # Array indexing: name[index]
                self.next()
                idx_ir = self.parse_expr_ir()
                self.expect('sym', ']')
                arr_ty = self.var_type(name)
                import re as _re
                m = _re.match(r'\[(\w+);\s*(\d+)\]', arr_ty)
                elem_ty = m.group(1) if m else 'i32'
                return (
                    f'          (array_get {elem_ty}\n'
                    f'            (ident {name})\n'
                    f'{idx_ir}'
                    '          )\n'
                ), elem_ty
            if self.peek().kind == 'sym' and self.peek().text == '(':
                self.next()
                # str_len(s) and str_ptr(s) intrinsics
                if name == 'str_len':
                    arg_ir = self.parse_expr_ir()
                    self.expect('sym', ')')
                    return f'          (str_len\n{arg_ir}          )\n', 'i32'
                if name == 'str_ptr':
                    arg_ir = self.parse_expr_ir()
                    self.expect('sym', ')')
                    return f'          (str_ptr\n{arg_ir}          )\n', 'i32'
                if name in self.fn_return_struct:
                    raise ParseError(f'struct-return call must be used in struct let initialization: {name}')
                inner = self.parse_call_args_ir()
                self.expect('sym', ')')
                if not inner:
                    return f'          (call {name})\n', 'i32'
                return f'          (call {name}\n{inner}          )\n', 'i32'
            return f'          (ident {name})\n', self.var_type(name)
        if t.kind == 'sym' and t.text == '(':
            self.next()
            ir, ty = self.parse_expr_typed()
            self.expect('sym', ')')
            return ir, ty
        if t.kind == 'sym' and t.text == '!':
            self.next()
            e_ir, e_ty = self.parse_term_typed()
            return (
                '          (binary eq\n'
                f'{e_ir}'
                '          (int 0)\n'
                '          )\n'
            ), 'i32'
        raise ParseError(f'unexpected token in expression: {t.kind}:{t.text}')


def main() -> int:
    ap = argparse.ArgumentParser(description='Compile Coatl subset to coatl_ir v1')
    ap.add_argument('input', help='input .coatl file')
    ap.add_argument('-o', '--output', required=True, help='output .ir file')
    args = ap.parse_args()

    if not args.input.endswith('.coatl'):
        raise SystemExit(f'input file must use .coatl extension: {args.input}')

    src = Path(args.input).read_text()
    toks = tokenize(src)
    p = Parser(toks)
    ir = p.parse_program_ir()
    Path(args.output).write_text(ir)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
