#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SELFHOST="$ROOT_DIR/selfhost/build_with_selfhost.sh"
TMP_DIR="$(mktemp -d /tmp/coatl-selfhost-runtime.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

compile_selfhost() {
  local src="$1"
  local out="$2"
  "$BUILD_SELFHOST" build "$ROOT_DIR/$src" -o "$out" >/dev/null
}

assert_ret() {
  local wat="$1"
  local expected="$2"
  local name="$3"
  local out
  out=$(wasmtime --invoke main "$wat")
  local got
  got=$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')
  if [[ "$got" != "$expected" ]]; then
    echo "[FAIL] $name: expected ret=$expected got ret=$got"
    printf '%s\n' "$out"
    exit 1
  fi
}

echo "[selfhost-runtime] mem_test"
mem_wat="$TMP_DIR/mem_test.wat"
compile_selfhost "tests/mem_test.coatl" "$mem_wat"
assert_ret "$mem_wat" "142" "mem_test"

echo "[selfhost-runtime] array_sim"
arr_wat="$TMP_DIR/array_sim.wat"
compile_selfhost "tests/array_sim.coatl" "$arr_wat"
assert_ret "$arr_wat" "100" "array_sim"

echo "[selfhost-runtime] byte_test"
byte_wat="$TMP_DIR/byte_test.wat"
compile_selfhost "tests/byte_test.coatl" "$byte_wat"
assert_ret "$byte_wat" "389" "byte_test"

echo "[selfhost-runtime] hello"
hello_wat="$TMP_DIR/hello.wat"
compile_selfhost "examples/hello.coatl" "$hello_wat"
hello_out=$(wasmtime --invoke main "$hello_wat")
hello_ret=$(printf '%s\n' "$hello_out" | awk 'NF { line=$0 } END { print line }')
if [[ "$hello_ret" != "0" ]]; then
  echo "[FAIL] hello: expected ret=0 got ret=$hello_ret"
  printf '%s\n' "$hello_out"
  exit 1
fi
if ! printf '%s\n' "$hello_out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] hello: expected output to include 'Hello, world!'"
  printf '%s\n' "$hello_out"
  exit 1
fi

echo "selfhost runtime suite passed (seed-only)"
