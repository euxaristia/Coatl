#!/usr/bin/env python3
import sys

def usage():
    print("usage: coatl_subset_to_ir.py <input.coatl> -o <output.ir>", file=sys.stderr)
    sys.exit(1)

if len(sys.argv) < 4:
    usage()

input_file = sys.argv[1]
if sys.argv[2] != "-o":
    usage()
output_file = sys.argv[3]

with open(input_file, "r") as f:
    src = f.read()

# Tokenizer
tokens = []
pos = 0
length = len(src)

while pos < length:
    c = src[pos]
    if c.isspace():
        pos += 1
        continue
    
    if c == '/' and pos + 1 < length and src[pos+1] == '/':
        pos += 2
        while pos < length and src[pos] != '\n':
            pos += 1
        continue

    if c.isalpha() or c == '_':
        start = pos
        pos += 1
        while pos < length and (src[pos].isalnum() or src[pos] == '_'):
            pos += 1
        tokens.append(('ident', src[start:pos]))
        continue

    if c.isdigit():
        start = pos
        pos += 1
        while pos < length and (src[pos].isdigit() or src[pos] == '.'):
            pos += 1
        if pos + 2 < length and src[pos] == 'i' and src[pos+1] == '6' and src[pos+2] == '4':
            pos += 3
        tokens.append(('num', src[start:pos]))
        continue

    if c == '"':
        start = pos
        pos += 1
        while pos < length and src[pos] != '"':
            if src[pos] == '\\':
                pos += 2
            else:
                pos += 1
        pos += 1
        s_content = src[start+1:pos-1]
        import re
        def _hex_esc(m):
            return chr(int(m.group(1), 16))
        s_content = re.sub(r'\\x([0-9a-fA-F]{2})', _hex_esc, s_content)
        s_content = s_content.replace('\\n', '\n').replace('\\t', '\t').replace('\\r', '\r').replace('\\"', '"').replace('\\\\', '\\')
        tokens.append(('str', f'"{s_content}"'))
        continue

    # Symbols
    # 2-char symbols
    if pos + 1 < length:
        two = src[pos:pos+2]
        if two in ['->', '==', '<=', '>=', '&&', '||', '!=']:
            tokens.append(('sym', two))
            pos += 2
            continue
            
    # 1-char symbols
    if c in "(){}[],;:+-*/.<>!=":
        tokens.append(('sym', c))
        pos += 1
        continue

    print(f"Unknown char: {c} at {pos}", file=sys.stderr)
    sys.exit(1)

tokens.append(('eof', ''))

tok_idx = 0
def peek(n=0):
    if tok_idx + n < len(tokens):
        return tokens[tok_idx + n]
    return ('eof', '')

def consume():
    global tok_idx
    t = peek()
    tok_idx += 1
    return t

def expect(k, v=None):
    t = peek()
    if t[0] != k or (v is not None and t[1] != v):
        print(f"Expected {k} {v}, got {t}", file=sys.stderr)
        sys.exit(1)
    return consume()

# Parser
ir_out = []
NL = chr(10)

structs = {}        # name -> [(field_name, field_type), ...]
var_types = {}      # var_name -> type_name
fn_ret_types = {}   # fn_name -> return_type

def emit(s):
    ir_out.append(s)

def parse_struct_def():
    consume()  # 'struct'
    name = expect('ident')[1]
    expect('sym', '{')
    fields = []
    while not (peek()[0] == 'sym' and peek()[1] == '}'):
        fname = expect('ident')[1]
        expect('sym', ':')
        ftype = expect('ident')[1]
        fields.append((fname, ftype))
        if peek()[0] == 'sym' and peek()[1] == ',':
            consume()
    expect('sym', '}')
    structs[name] = fields

def parse_program():
    # Parse struct definitions first
    while peek()[0] == 'ident' and peek()[1] == 'struct':
        parse_struct_def()
    # Emit header with structs
    structs_ir = "(structs"
    for sname, fields in structs.items():
        structs_ir += " (struct " + sname
        for fname, ftype in fields:
            structs_ir += " (field " + fname + " " + ftype + ")"
        structs_ir += ")"
    structs_ir += ")"
    emit("(coatl_ir v1" + NL + "  " + structs_ir + NL + "  (functions" + NL)
    while peek()[0] != 'eof':
        if peek()[0] == 'ident' and peek()[1] == 'fn':
            parse_fn()
        else:
            consume()
    emit("  )" + NL + ")" + NL)

def parse_fn():
    var_types.clear()
    consume() # fn
    name = expect('ident')[1]
    emit(f"    (fn {name}" + NL)
    expect('sym', '(')
    emit("      (params")
    while (peek()[0] != 'sym' or peek()[1] != ')') and peek()[0] != 'eof':
        pn = expect('ident')[1]
        expect('sym', ':')
        pt = expect('ident')[1]
        var_types[pn] = pt
        emit(f"" + NL + f"        (param {pn} {pt})")
        if peek()[0] == 'sym' and peek()[1] == ',':
            consume()
    expect('sym', ')')
    emit("" + NL + "      )" + NL)

    expect('sym', '->')
    rt = expect('ident')[1]
    fn_ret_types[name] = rt
    emit(f"      (ret {rt})" + NL)

    expect('sym', '{')
    emit("      (block" + NL)
    parse_block_stmts()
    expect('sym', '}')
    emit("      )" + NL + "    )" + NL)

def parse_block_stmts():
    while (peek()[0] != 'sym' or peek()[1] != '}') and peek()[0] != 'eof':
        parse_stmt()

def parse_stmt():
    t = peek()
    if t[0] == 'ident':
        if t[1] == 'let':
            consume()
            n = expect('ident')[1]
            expect('sym', ':')
            ty = expect('ident')[1]
            var_types[n] = ty
            expect('sym', '=')
            expr_str, _ = parse_expr()
            emit(f"        (let {n} {ty}" + NL)
            emit(expr_str)
            emit("        )" + NL)
            if peek()[0] == 'sym' and peek()[1] == ';': consume()
        elif t[1] == 'return':
            consume()
            expr_str, _ = parse_expr()
            emit("        (return" + NL)
            emit(expr_str)
            emit("        )" + NL)
            if peek()[0] == 'sym' and peek()[1] == ';': consume()
        elif t[1] == 'if':
            consume()
            expr_str, _ = parse_expr()
            emit("        (if" + NL)
            emit(expr_str)
            expect('sym', '{')
            emit("          (block" + NL)
            parse_block_stmts()
            expect('sym', '}')
            emit("          )" + NL)
            if peek()[0] == 'ident' and peek()[1] == 'else':
                consume()
                expect('sym', '{')
                emit("          (else" + NL + "            (block" + NL)
                parse_block_stmts()
                expect('sym', '}')
                emit("            )" + NL + "          )" + NL)
            emit("        )" + NL)
        elif t[1] == 'while':
            consume()
            expr_str, _ = parse_expr()
            emit("        (while" + NL)
            emit(expr_str)
            expect('sym', '{')
            emit("          (block" + NL)
            parse_block_stmts()
            expect('sym', '}')
            emit("          )" + NL + "        )" + NL)
        else:
            # check field assignment: ident.field = expr
            if peek(1)[0] == 'sym' and peek(1)[1] == '.' and peek(3)[0] == 'sym' and peek(3)[1] == '=':
                var_name = consume()[1]
                consume()  # '.'
                field_name = expect('ident')[1]
                consume()  # '='
                expr_str, _ = parse_expr()
                emit(f"        (field_assign {var_name} {field_name}" + NL)
                emit(expr_str)
                emit("        )" + NL)
                if peek()[0] == 'sym' and peek()[1] == ';': consume()
            # check assignment
            elif peek(1)[0] == 'sym' and peek(1)[1] == '=':
                n = consume()[1]
                consume() # =
                expr_str, _ = parse_expr()
                emit(f"        (assign {n}" + NL)
                emit(expr_str)
                emit("        )" + NL)
                if peek()[0] == 'sym' and peek()[1] == ';': consume()
            else:
                expr_str, _ = parse_expr()
                emit("        (expr" + NL)
                emit(expr_str)
                emit("        )" + NL)
                if peek()[0] == 'sym' and peek()[1] == ';': consume()
    else:
        expr_str, _ = parse_expr()
        emit("        (expr" + NL)
        emit(expr_str)
        emit("        )" + NL)
        if peek()[0] == 'sym' and peek()[1] == ';': consume()

def get_ty_suffix(ty):
    if ty == 'i64': return ' i64'
    return ''

def parse_expr():
    return parse_or()

def parse_or():
    lhs_str, l_ty = parse_and()
    while peek()[0] == 'sym' and peek()[1] == '||':
        consume()
        rhs_str, _ = parse_and()
        lhs_str = f"          (binary or{NL}{lhs_str}{rhs_str}          ){NL}"
        l_ty = 'bool'
    return lhs_str, l_ty

def parse_and():
    lhs_str, l_ty = parse_cmp()
    while peek()[0] == 'sym' and peek()[1] == '&&':
        consume()
        rhs_str, _ = parse_cmp()
        lhs_str = f"          (binary and{NL}{lhs_str}{rhs_str}          ){NL}"
        l_ty = 'bool'
    return lhs_str, l_ty

def parse_cmp():
    lhs_str, l_ty = parse_add()
    if peek()[0] == 'sym' and peek()[1] in ['<', '>', '<=', '>=', '==', '!=']:
        op = consume()[1]
        rhs_str, r_ty = parse_add()
        res_ty = l_ty if priority(l_ty) > priority(r_ty) else r_ty
        lhs_str = f"          (binary {op_name(op)}{get_ty_suffix(res_ty)}{NL}{lhs_str}{rhs_str}          ){NL}"
        return lhs_str, 'bool'
    return lhs_str, l_ty

def op_name(op):
    if op == '<': return 'lt'
    if op == '>': return 'gt'
    if op == '<=': return 'le'
    if op == '>=': return 'ge'
    if op == '==': return 'eq'
    if op == '!=': return 'ne'
    if op == '+': return 'add'
    if op == '-': return 'sub'
    if op == '*': return 'mul'
    if op == '/': return 'div'
    return op

def priority(ty):
    if ty == 'bool': return 3
    if ty == 'i64': return 2
    return 1

def parse_add():
    lhs_str, l_ty = parse_mul()
    while peek()[0] == 'sym' and peek()[1] in ['+', '-']:
        op = consume()[1]
        rhs_str, r_ty = parse_mul()
        res_ty = l_ty if priority(l_ty) > priority(r_ty) else r_ty
        lhs_str = f"          (binary {op_name(op)}{get_ty_suffix(res_ty)}{NL}{lhs_str}{rhs_str}          ){NL}"
        l_ty = res_ty
    return lhs_str, l_ty

def parse_mul():
    lhs_str, l_ty = parse_term()
    while peek()[0] == 'sym' and peek()[1] in ['*', '/']:
        op = consume()[1]
        rhs_str, r_ty = parse_term()
        res_ty = l_ty if priority(l_ty) > priority(r_ty) else r_ty
        lhs_str = f"          (binary {op_name(op)}{get_ty_suffix(res_ty)}{NL}{lhs_str}{rhs_str}          ){NL}"
        l_ty = res_ty
    return lhs_str, l_ty

def parse_term():
    t = peek()
    if t[0] == 'sym' and t[1] == '!':
        consume()
        rhs_str, _ = parse_term()
        s = f"          (binary eq{NL}{rhs_str}          (int 0){NL}          ){NL}"
        return s, 'bool'
    if t[0] == 'sym' and t[1] == '(':
        consume()
        s, ty = parse_expr()
        expect('sym', ')')
        return s, ty
    
    consume()
    if t[0] == 'num':
        val = t[1]
        if val.endswith('i64'):
            return f"          (int_i64 {val[:-3]}){NL}", 'i64'
        return f"          (int {val}){NL}", 'i32'
    if t[0] == 'str':
        return f"          (string_typed {t[1]}){NL}", 'str'
    if t[0] == 'ident':
        if t[1] == 'true':
            return f"          (bool 1){NL}", 'bool'
        if t[1] == 'false':
            return f"          (bool 0){NL}", 'bool'
        # Struct literal: StructName { field: expr, ... }
        if t[1] in structs and peek()[0] == 'sym' and peek()[1] == '{':
            consume()  # '{'
            sname = t[1]
            fields = structs[sname]
            field_exprs = {}
            while not (peek()[0] == 'sym' and peek()[1] == '}'):
                fname = expect('ident')[1]
                expect('sym', ':')
                fexpr, fty = parse_expr()
                field_exprs[fname] = fexpr
                if peek()[0] == 'sym' and peek()[1] == ',':
                    consume()
            consume()  # '}'
            # Emit in declaration order
            s = f"          (struct_lit {sname}{NL}"
            for fname, ftype in fields:
                s += field_exprs[fname]
            s += f"          ){NL}"
            return s, sname
        if peek()[0] == 'sym' and peek()[1] == '(':
            consume()
            if t[1] == 'str_len':
                arg_str, _ = parse_expr()
                consume()
                return f"          (str_len{NL}{arg_str}          ){NL}", 'i32'
            if t[1] == 'str_ptr':
                arg_str, _ = parse_expr()
                consume()
                return f"          (str_ptr{NL}{arg_str}          ){NL}", 'i32'

            s = f"          (call {t[1]}{NL}"
            while (peek()[0] != 'sym' or peek()[1] != ')') and peek()[0] != 'eof':
                arg_str, _ = parse_expr()
                s += arg_str
                if peek()[0] == 'sym' and peek()[1] == ',': consume()
            consume()
            s += f"          ){NL}"
            ret_ty = fn_ret_types.get(t[1], 'i32')
            return s, ret_ty

        # Check for field access: ident.field
        ident_name = t[1]
        result_str = f"          (ident {ident_name}){NL}"
        result_ty = var_types.get(ident_name, 'i32')
        while peek()[0] == 'sym' and peek()[1] == '.':
            consume()  # '.'
            field_name = expect('ident')[1]
            result_str = f"          (field {ident_name} {field_name}){NL}"
            result_ty = 'i32'  # field access on 2-field i32 structs always yields i32
        return result_str, result_ty
    return "", 'i32'

parse_program()

with open(output_file, "w") as f:
    f.write("".join(ir_out))