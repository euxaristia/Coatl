#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT_DIR/tools/coatl_subset_to_ir.bin"

input=""
output=""
input="$1"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done

printf '%s -o %s\n' "$(realpath "$input")" "$(realpath "$output")" | "$BIN"
