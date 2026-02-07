#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-type-f32.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[type-f32] compiling type_f32_smoke.coatl"
IR="$TMP_DIR/type_f32_smoke.ir"
WAT="$TMP_DIR/type_f32_smoke.wat"

python3 "$ROOT_DIR/tools/coatl_subset_to_ir.py" "$ROOT_DIR/tests/type_f32_smoke.coatl" -o "$IR"
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "21" ]]; then
  echo "[FAIL] expected 21, got $ret"
  echo "WAT:"
  cat "$WAT"
  exit 1
fi
echo "  ok (type_f32_smoke => 21)"
echo "type_f32_smoke passed"
