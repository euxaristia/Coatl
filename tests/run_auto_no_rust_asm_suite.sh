#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MEE_NO_RUST=1 MEE_ASM_TOOLCHAIN=auto "$ROOT_DIR/tests/run_ir_x86_subset_asm_smoke.sh"
