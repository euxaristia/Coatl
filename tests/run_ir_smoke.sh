#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER_DIR="$ROOT_DIR/compiler"
TMP_DIR="$(mktemp -d /tmp/mee-ir-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

emit_ir() {
  local src="$1"
  local out="$2"
  (cd "$COMPILER_DIR" && cargo run --quiet -- build "$src" --emit=ir -o "$out")
}

echo "[ir-smoke] hello"
HELLO_IR="$TMP_DIR/hello.ir"
emit_ir "$ROOT_DIR/examples/hello.mee" "$HELLO_IR"
grep -Fq "(mee_ir v0" "$HELLO_IR"
grep -Fq "(fn main" "$HELLO_IR"
grep -Fq "(call __fd_write" "$HELLO_IR"

echo "[ir-smoke] struct chain"
STRUCT_IR="$TMP_DIR/struct_chain.ir"
emit_ir "$ROOT_DIR/tests/struct_chain_calls.mee" "$STRUCT_IR"
grep -Fq "(struct Point" "$STRUCT_IR"
grep -Fq "(ret (struct Point))" "$STRUCT_IR"
grep -Fq "(field x" "$STRUCT_IR"
grep -Fq "(call sum_point" "$STRUCT_IR"

echo "ir smoke suite passed"
