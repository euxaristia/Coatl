#!/usr/bin/env python3
import sys
import subprocess
import os

def main():
    print('Running ./tests/run_x86_runtime_suite_ir_no_rust.py (generated replacement for ./tests/run_x86_runtime_suite_ir_no_rust.sh)')
    env = os.environ.copy()
    env['COATL_NO_RUST'] = '1'
    subprocess.run(['python3', '"$ROOT_DIR/tests/run_x86_runtime_suite.sh"'], env=env)
if __name__ == '__main__':
    main()
