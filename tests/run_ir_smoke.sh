#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

emit_ir() {
  local src="$1"
  local out="$2"
  "$ROOT_DIR/coatl" build "$src" --toolchain=ir -o "$out"
}

echo "[ir-smoke] hello"
HELLO_IR="$TMP_DIR/hello.ir"
emit_ir "$ROOT_DIR/examples/hello.coatl" "$HELLO_IR"
grep -Fq "(coatl_ir v1" "$HELLO_IR"
grep -Fq "(fn main" "$HELLO_IR"
grep -Fq "(call __fd_write" "$HELLO_IR"

echo "[ir-smoke] struct chain"
STRUCT_IR="$TMP_DIR/struct_chain.ir"
emit_ir "$ROOT_DIR/tests/struct_chain_calls.coatl" "$STRUCT_IR"
grep -Fq "(fn make_point" "$STRUCT_IR"
grep -Fq "(param p Point)" "$STRUCT_IR"
grep -Fq "(call sum_point" "$STRUCT_IR"

echo "ir smoke suite passed"
