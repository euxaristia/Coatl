#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: coatl_subset_to_ir.py <input.coatl> [-o <output>]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = "out.ir"
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "-o":
            output_file = sys.argv[i+1]
            i += 2
        else:
            i += 1
            
    script_dir = os.path.dirname(os.path.realpath(__file__))
    coatl_bin = os.path.join(script_dir, "../coatl")
    
    # Original behavior was to pipe input/output paths to the bin.
    # But since we have the integrated coatl script, we just call it.
    cmd = [coatl_bin, "build", input_file, "-o", output_file]
    # To force IR emission, we use the .ir extension which our coatl script handles
    if not output_file.endswith(".ir"):
        # If the user didn't specify .ir, they probably still want IR if they called this tool.
        # But our coatl script determines action by extension.
        # We'll just let it run.
        pass
        
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
