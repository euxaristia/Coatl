#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-x86-subset-asm.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v gcc >/dev/null 2>&1; then
  echo "gcc is required but not found in PATH"
  exit 1
fi

build_bin() {
  local src="$1"
  local bin="$2"
  local asm="$TMP_DIR/$(basename "$bin").s"
  "$ROOT_DIR/mee" build "$src" --emit=asm --toolchain=ir -o "$asm"
  gcc -no-pie "$asm" -o "$bin"
}

assert_rc() {
  local expected="$1"
  local got="$2"
  local label="$3"
  if [[ "$got" != "$expected" ]]; then
    echo "[FAIL] $label expected rc=$expected got rc=$got"
    exit 1
  fi
}

echo "[ir-x86-subset-asm] hello"
HELLO_BIN="$TMP_DIR/hello"
build_bin "$ROOT_DIR/examples/hello.mee" "$HELLO_BIN"
hello_out="$("$HELLO_BIN")"
hello_rc=$?
assert_rc 0 "$hello_rc" "hello"
if ! printf '%s\n' "$hello_out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] hello output missing"
  printf '%s\n' "$hello_out"
  exit 1
fi

echo "[ir-x86-subset-asm] mem_test"
MEM_BIN="$TMP_DIR/mem"
build_bin "$ROOT_DIR/tests/mem_test.mee" "$MEM_BIN"
set +e
"$MEM_BIN"
mem_rc=$?
set -e
assert_rc 142 "$mem_rc" "mem_test"

echo "[ir-x86-subset-asm] struct chain"
STRUCT_BIN="$TMP_DIR/struct"
build_bin "$ROOT_DIR/tests/struct_chain_calls.mee" "$STRUCT_BIN"
set +e
"$STRUCT_BIN"
struct_rc=$?
set -e
assert_rc 6 "$struct_rc" "struct_chain_calls"

echo "[ir-x86-subset-asm] fd_read"
READ_BIN="$TMP_DIR/read"
build_bin "$ROOT_DIR/tests/x86_fd_read_test.mee" "$READ_BIN"
set +e
printf "abcd" | "$READ_BIN"
read_rc=$?
set -e
assert_rc 4 "$read_rc" "x86_fd_read_test"

echo "[ir-x86-subset-asm] path_open/write/close"
WRITE_BIN="$TMP_DIR/write"
build_bin "$ROOT_DIR/tests/x86_path_open_write_test.mee" "$WRITE_BIN"
rm -f /tmp/mee_x86_io_test.txt
set +e
"$WRITE_BIN"
write_rc=$?
set -e
assert_rc 3 "$write_rc" "x86_path_open_write_test"
if [[ ! -f /tmp/mee_x86_io_test.txt ]]; then
  echo "[FAIL] x86_path_open_write_test missing output file"
  exit 1
fi
if ! printf "OK\n" | cmp -s - /tmp/mee_x86_io_test.txt; then
  echo "[FAIL] x86_path_open_write_test file contents mismatch"
  cat /tmp/mee_x86_io_test.txt
  exit 1
fi
rm -f /tmp/mee_x86_io_test.txt

echo "ir x86 subset asm smoke suite passed"
