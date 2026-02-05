#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COATL_NO_RUST=1 COATL_X86_TOOLCHAIN=auto "$ROOT_DIR/tests/run_x86_runtime_suite.sh"
