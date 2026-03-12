#!/usr/bin/env python3
import sys
import subprocess
import os
import platform

def main():
    if len(sys.argv) < 4:
        print("Usage: link_aarch64_elf.py <input.o> -o <output>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[3]
    
    script_dir = os.path.dirname(os.path.realpath(__file__))
    intrinsics = os.path.join(script_dir, "../runtime/intrinsics_aarch64.s")
    
    cc = os.environ.get("CC", "cc")
    if platform.machine() != "aarch64" and cc == "cc":
        # Check if we have a cross-compiler
        if subprocess.run(["command", "-v", "aarch64-linux-gnu-gcc"], shell=True, capture_output=True).returncode == 0:
            cc = "aarch64-linux-gnu-gcc"

    cmd = [cc, "-fPIE", "-pie", "-e", "coatl_start", input_file, intrinsics, "-o", output_file]
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
