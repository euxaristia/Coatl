#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MEE_NO_RUST=1 MEE_X86_TOOLCHAIN=ir "$ROOT_DIR/tests/run_x86_runtime_suite.sh"
