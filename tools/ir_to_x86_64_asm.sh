#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COATL_BIN="${COATL_BIN:-$(command -v coatl || true)}"

if [[ -z "$COATL_BIN" && -x "$ROOT_DIR/coatl" ]]; then
  COATL_BIN="$ROOT_DIR/coatl"
fi
MODULE="/tmp/coatl-ir-to-x86-64.wat"

usage() {
  cat <<'EOF' >&2
usage:
  tools/ir_to_x86_64_asm.sh <input.ir> -o <output.s>
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

input=""
output=""
input="$1"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      if [[ $# -lt 2 ]]; then
        echo "missing value for -o" >&2
        usage
        exit 1
      fi
      output="$2"
      shift 2
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$output" ]]; then
  echo "missing -o <output.s>" >&2
  usage
  exit 1
fi

if [[ -z "$COATL_BIN" || ! -x "$COATL_BIN" ]]; then
  echo "ir_to_x86_64_asm: coatl binary not found" >&2
  exit 1
fi
if ! command -v wasmtime >/dev/null 2>&1; then
  echo "ir_to_x86_64_asm: wasmtime not found" >&2
  exit 1
fi

if [[ ! -f "$MODULE" ]]; then
  "$COATL_BIN" build "$ROOT_DIR/tools/ir_to_x86_64_asm.coatl" --toolchain=selfhost -o "$MODULE" >/dev/null
fi

# WASI path_open uses fd 3 as base directory.
abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
abs_output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"
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

ret="$(printf '%s -o %s\n' "$rel_input" "$rel_output" | wasmtime --dir "$base_dir" --invoke main "$MODULE" 2>/dev/null)"
if [[ "$ret" != "0" ]]; then
  echo "ir_to_x86_64_asm: lowering failed (rc=$ret)" >&2
  exit 1
fi