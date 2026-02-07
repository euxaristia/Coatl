#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-x86-type-f32.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[x86-type-f32] compiling type_f32_smoke.coatl"
ASM="$TMP_DIR/type_f32_smoke.s"
BIN="$TMP_DIR/type_f32_smoke.bin"

"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/type_f32_smoke.coatl" --emit=bin --toolchain=ir -o "$BIN"

echo "Running binary..."
set +e
"$BIN"
ret=$?
set -e

if [[ "$ret" != "21" ]]; then
  echo "[FAIL] expected 21, got $ret"
  exit 1
fi
echo "  ok (type_f32_smoke => 21)"
echo "x86_type_f32_smoke passed"
