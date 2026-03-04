#!/usr/bin/env python3
import subprocess
import os
import tempfile
import sys
import platform

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    coatl_bin = os.path.join(root_dir, "coatl")
    
    if platform.system() != "Linux":
        print("ir x86 subset asm smoke currently supports Linux only")
        sys.exit(0)

    with tempfile.TemporaryDirectory(prefix="coatl-x86-smoke-") as tmp_dir:
        def build_bin(src, bin_name):
            bin_path = os.path.join(tmp_dir, bin_name)
            subprocess.run([coatl_bin, "build", src, "--arch=x86_64", "-o", bin_path], check=True)
            return bin_path

        def assert_rc(expected, got, label):
            if expected != got:
                print(f"[FAIL] {label} expected rc={expected} got rc={got}")
                sys.exit(1)

        tests = [
            ("examples/hello.coatl", "hello", 0),
            ("tests/mem_test.coatl", "mem", 142),
            ("tests/byte_test.coatl", "byte", 133),
            ("tests/array_sim.coatl", "array", 100),
            ("tests/ir_subset_control_flow.coatl", "control", 77),
            ("tests/nested_let_scope_subset.coatl", "nested-let", 7),
            ("tests/struct_chain_calls.coatl", "struct", 6),
            ("tests/struct_return_basic.coatl", "struct-return-basic", 15),
            ("tests/struct_param_pass.coatl", "struct-param", 9),
            ("tests/struct_field_mutation_subset.coatl", "struct-mutate", 33),
            ("tests/struct_nested_arg_subset.coatl", "struct-nested", 6),
            ("tests/struct_return_if_subset.coatl", "struct-if", 36),
            ("tests/struct_return_while_subset.coatl", "struct-while", 9),
        ]

        for src_rel, bin_name, expected_rc in tests:
            print(f"[ir-x86-subset-asm] {bin_name}")
            src_path = os.path.join(root_dir, src_rel)
            bin_path = build_bin(src_path, bin_name)
            
            cp = subprocess.run([bin_path], capture_output=True)
            assert_rc(expected_rc, cp.returncode, bin_name)
            
            if bin_name == "hello":
                if b"Hello, world!" not in cp.stdout:
                    print(f"[FAIL] hello output missing: {cp.stdout}")
                    sys.exit(1)

        # Special cases
        print("[ir-x86-subset-asm] fd_read")
        read_bin = build_bin(os.path.join(root_dir, "tests/x86_fd_read_test.coatl"), "read")
        cp = subprocess.run([read_bin], input=b"abcd", capture_output=True)
        assert_rc(4, cp.returncode, "fd_read")

        print("[ir-x86-subset-asm] path_open/write/close")
        write_bin = build_bin(os.path.join(root_dir, "tests/x86_path_open_write_test.coatl"), "write")
        test_file = "/tmp/coatl_x86_io_test.txt"
        if os.path.exists(test_file): os.remove(test_file)
        cp = subprocess.run([write_bin])
        assert_rc(3, cp.returncode, "path_open_write")
        if not os.path.exists(test_file):
            print("[FAIL] missing output file")
            sys.exit(1)
        with open(test_file, 'r') as f:
            if f.read() != "OK\n":
                print("[FAIL] file content mismatch")
                sys.exit(1)
        os.remove(test_file)

        print("ir x86 subset asm smoke suite passed")

if __name__ == "__main__":
    main()
