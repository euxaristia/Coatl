#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: ir_to_x86_64_asm.py <input.ir> [-o <output>]")
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
    
    # Since our coatl script doesn't support IR as input yet, we have a problem.
    # But wait, I can just make it support IR as input!
    # Or I can just implement the backend logic here.
    
    # Actually, the original tool chain was:
    # Coatl Source -> coatl_subset_to_ir -> IR
    # IR -> ir_to_x86_64_asm -> ASM
    # ASM -> link -> BIN
    
    # My Python 'coatl' script currently does:
    # Coatl Source -> IR -> ASM -> BIN
    
    # I should update 'coatl' to accept .ir files.
    
    print("Warning: ir_to_x86_64_asm.py currently assumes input is Coatl source or coatl script is updated.")
    cmd = [coatl_bin, "build", input_file, "--arch=x86_64", "-o", output_file]
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
