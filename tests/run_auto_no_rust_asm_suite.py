#!/usr/bin/env python3
import sys
import subprocess
import os

def main():
    print('Running ./tests/run_auto_no_rust_asm_suite.py (generated replacement for ./tests/run_auto_no_rust_asm_suite.sh)')
    env = os.environ.copy()
    env['COATL_NO_RUST'] = '1'
    subprocess.run(['python3', '"$ROOT_DIR/tests/run_ir_x86_subset_asm_smoke.sh"'], env=env)
if __name__ == '__main__':
    main()
