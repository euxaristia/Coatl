#!/usr/bin/env python3
import sys
import subprocess
import os

def main():
    print('Running ./tests/run_no_rust_bin_ir_no_cc_smoke.py (generated replacement for ./tests/run_no_rust_bin_ir_no_cc_smoke.sh)')
    env = os.environ.copy()
    env['COATL_NO_RUST'] = '1'
if __name__ == '__main__':
    main()
