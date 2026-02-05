#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-backend.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[ir-backend] compile hello via toolchain=ir"
cd "$ROOT_DIR"
HELLO_WAT="$TMP_DIR/hello_ir_backend.wat"
./mee build ./examples/hello.mee --emit=wat --toolchain=ir -o "$HELLO_WAT"

if [[ ! -s "$HELLO_WAT" ]]; then
  echo "[FAIL] no output WAT generated"
  exit 1
fi
if ! head -n 1 "$HELLO_WAT" | grep -q "^(module"; then
  echo "[FAIL] invalid WAT output"
  exit 1
fi

out="$(wasmtime --invoke main "$HELLO_WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "0" ]]; then
  echo "[FAIL] expected return 0, got $ret"
  printf '%s\n' "$out"
  exit 1
fi
if ! printf '%s\n' "$out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] expected hello output"
  printf '%s\n' "$out"
  exit 1
fi

echo "[ir-backend] compile struct case via toolchain=ir (fallback-capable)"
STRUCT_WAT="$TMP_DIR/struct_ir_backend.wat"
./mee build ./tests/struct_param_pass.mee --emit=wat --toolchain=ir -o "$STRUCT_WAT"
struct_out="$(wasmtime --invoke main "$STRUCT_WAT")"
struct_ret="$(printf '%s\n' "$struct_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_ret" != "9" ]]; then
  echo "[FAIL] expected struct return 9, got $struct_ret"
  printf '%s\n' "$struct_out"
  exit 1
fi

echo "ir backend smoke suite passed"
