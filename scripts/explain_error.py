#!/usr/bin/env python3
import sys
import re

ERRORS = {
    # Parser Errors
    601: "Expected 'fn'",
    602: "Expected function name",
    603: "Expected '(' after function name",
    604: "Failed to parse parameters",
    605: "Expected ')' after parameters",
    606: "Expected '->' after parameters",
    607: "Failed to parse return type",
    608: "Expected '{' before function body",
    610: "Expected '}' after function body",
    611: "Expected top-level declaration (fn or struct)",
    612: "Expected 'struct'",
    613: "Expected struct name",
    614: "Expected '{' after struct name",
    615: "Expected field name in struct",
    616: "Expected ':' after field name",
    617: "Expected 'i32' field type (only i32 supported in structs for now)",
    618: "Expected '}' after struct fields",
    619: "Too many fields in struct",
    700: "Expected expression",
    701: "Expected terminal (int, ident, etc.)",
    
    # Intrinsic / Special errors
    3301: "Unknown intrinsic or function",
    3302: "Intrinsic 'str_len' or 'str_ptr' expects 1 argument",
    3303: "__fd_read/__fd_write expects 2 arguments",
    3304: "Invalid constant argument to intrinsic",
    3305: "__path_open expects 4 arguments",
    3306: "__path_open (extended) expects 9 arguments",
    3307: "__fd_close expects 1 argument",
    3308: "Function call argument count mismatch",

    # Semantic Errors
    7201: "Undefined function",
    7202: "Function argument count mismatch",
    7203: "Type mismatch in expression",
    7210: "Numeric operator expected numeric operand",
    7220: "Comparison operator expected numeric operand",
    7225: "Logical operator expected boolean operand",
    7226: "Unary '!' expected boolean operand",
    7227: "'if' or 'while' condition must be i32 (0/1)",
    7230: "Type mismatch in assignment or 'let'",
    7231: "Return type mismatch",
    7232: "'if' condition must be boolean",
    7233: "'while' condition must be boolean",
    7240: "Invalid AST node in statement position",
    7250: "Expected block node",
    7251: "Expected statement node",
}

def explain_line(line):
    parts = line.strip().split()
    if not parts:
        return False

    try:
        # Check if first part is a potential error code (numeric, might start with -)
        code_raw = int(parts[0])
        code = abs(code_raw)
        
        # Sometimes it's 4000 + ident_id for undefined local
        if 4000 <= code < 5000:
            msg = f"Undefined local variable (ID: {code - 4000})"
        else:
            msg = ERRORS.get(code, f"Unknown error code {code}")

        pos = parts[1] if len(parts) > 1 else "?"
        tok = parts[2] if len(parts) > 2 else "?"
        ln = parts[3] if len(parts) > 3 else "?"
        col = parts[4] if len(parts) > 4 else "?"

        print(f"\033[1;31mError:\033[0m {msg}")
        print(f"  \033[1mAt:\033[0m line {ln}, column {col} (pos {pos})")
        if tok != "0" and tok != "?":
            print(f"  \033[1mToken ID:\033[0m {tok}")
        return True

    except (ValueError, IndexError):
        return False

def main():
    if len(sys.argv) < 2:
        print("usage: explain_error.py '<output text>'")
        return

    full_text = " ".join(sys.argv[1:])
    lines = full_text.split('\n')
    
    found = False
    for line in lines:
        if explain_line(line):
            found = True
            break
            
    if not found:
        # If no numeric error line found, just print the original text
        print(full_text)

if __name__ == "__main__":
    main()