#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: cbyte_vm.py <input.cbyte>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    script_dir = os.path.dirname(os.path.realpath(__file__))
    coatl_bin = os.path.join(script_dir, "../coatl")
    
    cmd = [coatl_bin, "run-cbyte", input_file]
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
