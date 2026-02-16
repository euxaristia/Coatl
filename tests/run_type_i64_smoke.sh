#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-type-i64.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[type-i64] compiling type_i64_smoke.coatl"
IR="$TMP_DIR/type_i64_smoke.ir"
WAT="$TMP_DIR/type_i64_smoke.wat"

"$ROOT_DIR/tools/coatl_subset_to_ir.sh" "$ROOT_DIR/tests/type_i64_smoke.coatl" -o "$IR"
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "42" ]]; then
  echo "[FAIL] expected 42, got $ret"
  echo "WAT:"
  cat "$WAT"
  exit 1
fi
echo "  ok (type_i64_smoke => 42)"
echo "type_i64_smoke passed"
