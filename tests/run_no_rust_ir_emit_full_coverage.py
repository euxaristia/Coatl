#!/usr/bin/env python3
import sys
import subprocess
import os

def main():
    print('Running ./tests/run_no_rust_ir_emit_full_coverage.py (generated replacement for ./tests/run_no_rust_ir_emit_full_coverage.sh)')
    env = os.environ.copy()
    env['COATL_NO_RUST'] = '1'
if __name__ == '__main__':
    main()
