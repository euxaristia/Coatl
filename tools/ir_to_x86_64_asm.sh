#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT_DIR/tools/ir_to_x86_64_asm.bin"

input="$1"
shift
output=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done

abs_input="$(realpath "$input")"
abs_output="$(realpath "$output")"
input_dir="$(dirname "$abs_input")"
output_dir="$(dirname "$abs_output")"

if [[ "$input_dir" == "$output_dir" ]]; then
  base_dir="$input_dir"
  rel_input="$(basename "$abs_input")"
  rel_output="$(basename "$abs_output")"
else
  base_dir="/"
  rel_input="${abs_input#/}"
  rel_output="${abs_output#/}"
fi

# The native tool still expects input on stdin in the same format
cd "$base_dir"
printf '%s -o %s\n' "$rel_input" "$rel_output" | "$BIN"
