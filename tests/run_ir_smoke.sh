#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -d "$ROOT_DIR/compiler" || "${MEE_NO_RUST_BUILD:-0}" == "1" ]] || ! command -v cargo >/dev/null 2>&1; then
  echo "ir smoke suite skipped: rust compiler lane unavailable"
  exit 0
fi

emit_ir() {
  local src="$1"
  local out="$2"
  "$ROOT_DIR/mee" build "$src" --emit=ir --toolchain=rust -o "$out"
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
