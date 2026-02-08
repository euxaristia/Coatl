#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-x86-type-i64.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[x86-type-i64] compiling type_i64_smoke.coatl"
ASM="$TMP_DIR/type_i64_smoke.s"
BIN="$TMP_DIR/type_i64_smoke.bin"

# We use the full build pipeline: coatl -> ir -> asm -> bin
# Using --toolchain=ir to skip selfhost/auto logic and use python scripts
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/type_i64_smoke.coatl" --toolchain=ir -o "$BIN"

echo "Running binary..."
set +e
"$BIN"
ret=$?
set -e

if [[ "$ret" != "42" ]]; then
  echo "[FAIL] expected 42, got $ret"
  exit 1
fi
echo "  ok (type_i64_smoke => 42)"
echo "x86_type_i64_smoke passed"
