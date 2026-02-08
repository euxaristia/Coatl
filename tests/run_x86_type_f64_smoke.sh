#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-x86-type-f64.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[x86-type-f64] compiling type_f64_smoke.coatl"
ASM="$TMP_DIR/type_f64_smoke.s"
BIN="$TMP_DIR/type_f64_smoke.bin"

"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/type_f64_smoke.coatl" --toolchain=ir -o "$BIN"

echo "Running binary..."
set +e
"$BIN"
ret=$?
set -e

if [[ "$ret" != "44" ]]; then
  echo "[FAIL] expected 44, got $ret"
  exit 1
fi
echo "  ok (type_f64_smoke => 44)"
echo "x86_type_f64_smoke passed"
