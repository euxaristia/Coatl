#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT_DIR/tools/link_x86_64_elf.bin"
printf '%s -o %s\n' "$1" "$3" | "$BIN"
