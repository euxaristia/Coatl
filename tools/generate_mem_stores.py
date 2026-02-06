#!/usr/bin/env python3
"""
Utility to generate __mem_store8 calls for Coatl string literals.
Usage: python3 generate_mem_stores.py [--base BASE_EXPR] "string1" "string2" ...
"""
import sys
import codecs
import argparse

def main():
    parser = argparse.ArgumentParser(description="Generate Coatl __mem_store8 calls")
    parser.add_argument("--base", default="base", help="Base expression (default: 'base')")
    parser.add_argument("--offset", type=int, default=0, help="Starting offset (default: 0)")
    parser.add_argument("--no-null", action="store_true", help="Don't add null terminators")
    parser.add_argument("strings", nargs="+", help="Strings to encode")
    
    args = parser.parse_args()

    # Decode escapes in input strings
    strings = [codecs.decode(s, 'unicode_escape') for s in args.strings]
    base = args.base
    offset = args.offset
    
    for i, s in enumerate(strings):
        print(f"  // Literal: {repr(s)}")
        for j, char in enumerate(s):
            code = ord(char)
            # Handle some common escapes for the comment
            comment_char = char
            if char == '\n': comment_char = '\\n'
            elif char == '\t': comment_char = '\\t'
            elif char == '\r': comment_char = '\\r'
            elif char == '\'': comment_char = '\\\''
            elif char == '\\': comment_char = '\\\\'
            
            print(f"  __mem_store8({{base}} + {{offset}}, {{code}});  // '{{comment}}'".format(
                base=base, offset=offset, code=code, comment=comment_char))
            offset += 1
        
        if not args.no_null:
            print(f"  __mem_store8({base} + {offset}, 0);")
            offset += 1
        
        if i < len(strings) - 1:
            print()

if __name__ == "__main__":
    main()