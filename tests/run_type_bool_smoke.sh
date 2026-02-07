#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-type-bool.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[type-bool] compiling type_bool_smoke.coatl"
IR="$TMP_DIR/type_bool_smoke.ir"
WAT="$TMP_DIR/type_bool_smoke.wat"

python3 "$ROOT_DIR/tools/coatl_subset_to_ir.py" "$ROOT_DIR/tests/type_bool_smoke.coatl" -o "$IR"
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "10" ]]; then
  echo "[FAIL] expected 10, got $ret"
  exit 1
fi
echo "  ok (type_bool_smoke => 10)"
echo "type_bool_smoke passed"
