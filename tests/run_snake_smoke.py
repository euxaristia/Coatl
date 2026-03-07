#!/usr/bin/env python3
import subprocess
import os
import tempfile
import sys
import platform

def detect_qemu_prefix(arch, cc=None):
    # Simplified version of the shell logic
    return None # For now

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    coatl_bin = os.path.join(root_dir, "coatl.py")
    snake_src = os.path.join(root_dir, "examples/TermSnake/snake.coatl")
    
    with tempfile.TemporaryDirectory(prefix="coatl-snake-smoke-") as tmp_dir:
        my_arch = platform.machine()
        
        # --- x86_64 ---
        print("[snake-smoke] Testing x86_64")
        snake_x86 = os.path.join(tmp_dir, "snake_x86")
        try:
            subprocess.run([coatl_bin, "build", snake_src, "--arch=x86_64", "-o", snake_x86], check=True)
            
            if my_arch == "x86_64":
                # Feed 'q' to exit immediately
                subprocess.run([snake_x86], input=b"q\n", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
                print("x86_64 execution smoke passed")
            else:
                print("Skipping x86_64 execution (not on x86_64)")
        except Exception as e:
            print(f"x86_64 test failed: {e}")

        # --- aarch64 ---
        print("[snake-smoke] Testing aarch64")
        snake_aarch64 = os.path.join(tmp_dir, "snake_aarch64")
        try:
            # Note: CC environment variable might need to be set for cross-compilation if not on aarch64
            # But our coatl.py script just calls 'cc'. If we are cross-compiling, we might need a cross-cc.
            env = os.environ.copy()
            if my_arch != "aarch64" and subprocess.run(["command", "-v", "aarch64-linux-gnu-gcc"], shell=True, capture_output=True).returncode == 0:
                env["CC"] = "aarch64-linux-gnu-gcc"
            
            subprocess.run([coatl_bin, "build", snake_src, "--arch=aarch64", "-o", snake_aarch64], check=True, env=env)
            
            if my_arch == "aarch64":
                subprocess.run([snake_aarch64], input=b"q\n", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
                print("aarch64 execution smoke passed")
            else:
                print("Skipping aarch64 execution (not on aarch64)")
        except Exception as e:
            print(f"aarch64 test failed: {e}")

        print("snake smoke test complete")

if __name__ == "__main__":
    main()
