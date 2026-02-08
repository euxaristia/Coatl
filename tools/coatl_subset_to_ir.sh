#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COATL_BIN="${COATL_BIN:-$(command -v coatl || true)}"

if [[ -z "$COATL_BIN" && -x "$ROOT_DIR/coatl" ]]; then
  COATL_BIN="$ROOT_DIR/coatl"
fi
MODULE="/tmp/coatl-subset-to-ir.wat"

usage() {
  cat <<'EOF' >&2
usage:
  tools/coatl_subset_to_ir.sh <input.coatl> -o <output.ir>
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
  echo "missing -o <output.ir>" >&2
  usage
  exit 1
fi

if [[ -f "$ROOT_DIR/tools/coatl_subset_to_ir.py" ]]; then
  python3 "$ROOT_DIR/tools/coatl_subset_to_ir.py" "$input" -o "$output"
  exit $?
fi

if [[ -z "$COATL_BIN" || ! -x "$COATL_BIN" ]]; then
  # Fallback to python
  python3 "$ROOT_DIR/tools/coatl_subset_to_ir.py" "$input" -o "$output"
  exit 0
fi

if ! command -v wasmtime >/dev/null 2>&1; then
  python3 "$ROOT_DIR/tools/coatl_subset_to_ir.py" "$input" -o "$output"
  exit 0
fi

if [[ ! -f "$MODULE" ]]; then
  "$COATL_BIN" build "$ROOT_DIR/tools/coatl_subset_to_ir.coatl" --toolchain=selfhost -o "$MODULE" >/dev/null
fi

abs_input="$(realpath "$input")"
abs_output="$(realpath "$output" 2>/dev/null || echo "$(cd "$(dirname "$output")" && pwd)/$(basename "$output")")"

# Pass ONLY the arguments the tool expects: <input> -o <output>
ret="$(printf '%s -o %s\n' "$abs_input" "$abs_output" | wasmtime --dir / --invoke main "$MODULE" 2>/dev/null)"
if [[ "$ret" != "0" ]]; then
  echo "coatl_subset_to_ir: failed with rc=$ret" >&2
  exit 1
fi
