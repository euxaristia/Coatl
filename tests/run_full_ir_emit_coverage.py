#!/usr/bin/env python3
import subprocess
import os
import sys

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    coatl_bin = os.path.join(root_dir, "coatl")
    tests_dir = os.path.join(root_dir, "tests")
    
    coatl_files = [f for f in os.listdir(tests_dir) if f.endswith(".coatl")]
    # Add examples too
    coatl_files.append("../examples/hello.coatl")
    coatl_files.append("../examples/TermSnake/snake.coatl")

    failed = 0
    for f in coatl_files:
        src = os.path.join(tests_dir, f)
        print(f"Testing IR emission for {f}")
        try:
            subprocess.run([coatl_bin, "build", src, "--toolchain=ir", "-o", "/dev/null"], check=True)
        except:
            print(f"FAILED: {f}")
            failed += 1
            
    if failed > 0:
        print(f"{failed} tests failed")
        sys.exit(1)
    print("All IR emission tests passed")

if __name__ == "__main__":
    main()
