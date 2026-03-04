#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: ir_to_aarch64_asm.py <input.ir> [-o <output>]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = "out.s"
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "-o":
            output_file = sys.argv[i+1]
            i += 2
        else:
            i += 1
            
    script_dir = os.path.dirname(os.path.realpath(__file__))
    coatl_bin = os.path.join(script_dir, "../coatl")
    
    cmd = [coatl_bin, "build", input_file, "--arch=aarch64", "-o", output_file]
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
