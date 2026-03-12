#!/usr/bin/env python3
import subprocess
import os
import tempfile
import sys

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    coatl_bin = os.environ.get("COATL_BIN", os.path.join(root_dir, "coatl.py"))
    
    with tempfile.TemporaryDirectory(prefix="coatl-ir-smoke-") as tmp_dir:
        def emit_ir(src, out):
            if coatl_bin.endswith(".py"):
                subprocess.run(["python3", coatl_bin, "build", src, "--toolchain=ir", "-o", out], check=True)
            else:
                # Rust compiler generates IR if output ends in .ir
                subprocess.run([coatl_bin, src, "-o", out], check=True)

        print("[ir-smoke] hello")
        hello_ir = os.path.join(tmp_dir, "hello.ir")
        emit_ir(os.path.join(root_dir, "examples/hello.coatl"), hello_ir)
        with open(hello_ir, 'r') as f:
            content = f.read()
            assert "(coatl_ir v1" in content
            assert "(fn main" in content
            assert "(call __print" in content

        print("[ir-smoke] struct chain")
        struct_ir = os.path.join(tmp_dir, "struct_chain.ir")
        emit_ir(os.path.join(root_dir, "tests/struct_chain_calls.coatl"), struct_ir)
        with open(struct_ir, 'r') as f:
            content = f.read()
            assert "(fn make_point" in content
            assert "(ret Point)" in content
            assert "(call sum_point" in content

        print("ir smoke suite passed")
        
        # Test 3: Module Smoke
        print("[mod-smoke]")
        mod_ir = tempfile.mktemp(suffix=".ir")
        emit_ir(os.path.join(root_dir, "tests/module_smoke.coatl"), mod_ir)
        with open(mod_ir, 'r') as f:
            content = f.read()
            assert "(imports" in content
            assert "(fn main" in content
            assert "(fn print" in content
        print("module smoke suite passed")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
