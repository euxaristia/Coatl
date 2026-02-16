#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-type-str.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[type-str] compiling type_str_smoke.coatl"
IR="$TMP_DIR/type_str_smoke.ir"
WAT="$TMP_DIR/type_str_smoke.wat"

"$ROOT_DIR/tools/coatl_subset_to_ir.sh" "$ROOT_DIR/tests/type_str_smoke.coatl" -o "$IR"
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "5" ]]; then
  echo "[FAIL] expected 5, got $ret"
  echo "WAT:"
  cat "$WAT"
  exit 1
fi
echo "  ok (type_str_smoke => 5)"
echo "type_str_smoke passed"
