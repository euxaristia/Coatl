#!/usr/bin/env python3
import sys
import subprocess
import os

def main():
    if len(sys.argv) < 4:
        print("Usage: link_x86_64_elf.py <input.o> -o <output>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[3]
    
    # Use cc to link for now, as it's more reliable than a quick Python ELF rewrite
    # unless specifically asked to avoid system toolchain.
    # Coatl's intrinsics need to be linked too.
    script_dir = os.path.dirname(os.path.realpath(__file__))
    intrinsics = os.path.join(script_dir, "../tests/intrinsics.s")
    
    cmd = ["cc", "-fPIE", "-pie", "-e", "coatl_start", input_file, intrinsics, "-o", output_file]
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
