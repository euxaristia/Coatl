#!/usr/bin/env python3
import subprocess
import os
import tempfile
import sys
import platform

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    coatl_bin = os.path.join(root_dir, "coatl.py")
    
    with tempfile.TemporaryDirectory(prefix="coatl-aarch64-smoke-") as tmp_dir:
        def build_bin(src, bin_name):
            bin_path = os.path.join(tmp_dir, bin_name)
            env = os.environ.copy()
            if platform.machine() != "aarch64":
                if subprocess.run(["command", "-v", "aarch64-linux-gnu-gcc"], shell=True, capture_output=True).returncode == 0:
                    env["CC"] = "aarch64-linux-gnu-gcc"
            subprocess.run([coatl_bin, "build", src, "--arch=aarch64", "-o", bin_path], check=True, env=env)
            return bin_path

        tests = [
            ("tests/test_aarch64_minimal.coatl", "minimal", 0),
            ("tests/test_aarch64_tiny.coatl", "tiny", 42),
        ]

        for src_rel, bin_name, expected_rc in tests:
            print(f"[aarch64-smoke] {bin_name}")
            src_path = os.path.join(root_dir, src_rel)
            try:
                bin_path = build_bin(src_path, bin_name)
                if platform.machine() == "aarch64":
                    cp = subprocess.run([bin_path])
                    assert cp.returncode == expected_rc
                else:
                    print(f"Skipping execution of {bin_name} (not on aarch64)")
            except Exception as e:
                print(f"aarch64 {bin_name} test failed: {e}")

if __name__ == "__main__":
    main()
