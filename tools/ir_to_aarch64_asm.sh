#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT_DIR/tools/ir_to_aarch64_asm.bin"
printf '%s -o %s\n' "$1" "$3" | "$BIN"
