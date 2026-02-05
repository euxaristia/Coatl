#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-x86-suite.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
TOOLCHAIN="${MEE_X86_TOOLCHAIN:-rust}"
source "$ROOT_DIR/tests/lib_x86_link.sh"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "x86 runtime suite currently supports Linux only"
  exit 1
fi

if ! have_x86_link_toolchain; then
  echo "x86 runtime suite requires usable CC or as+ld"
  exit 1
fi

build_bin() {
  local src="$1"
  local out="$2"
  local asm="$TMP_DIR/$(basename "$out").s"
  "$ROOT_DIR/mee" build "$src" --emit=asm --toolchain="$TOOLCHAIN" -o "$asm"
  link_x86_asm_binary "$asm" "$out"
}

assert_rc() {
  local expected="$1"
  local got="$2"
  local name="$3"
  if [[ "$got" -ne "$expected" ]]; then
    echo "[FAIL] $name: expected rc=$expected got rc=$got"
    exit 1
  fi
}

echo "[x86-suite] hello output + rc"
HELLO_BIN="$TMP_DIR/hello.bin"
build_bin "$ROOT_DIR/examples/hello.mee" "$HELLO_BIN"
hello_out="$("$HELLO_BIN")"
hello_rc=$?
if [[ "$hello_out" != "Hello, world!" ]]; then
  echo "[FAIL] hello output mismatch"
  printf 'got: %q\n' "$hello_out"
  exit 1
fi
assert_rc 0 "$hello_rc" "hello"

echo "[x86-suite] mem intrinsics"
MEM_BIN="$TMP_DIR/mem.bin"
build_bin "$ROOT_DIR/tests/mem_test.mee" "$MEM_BIN"
set +e
"$MEM_BIN" >/dev/null 2>&1
mem_rc=$?
set -e
assert_rc 142 "$mem_rc" "mem_test"

echo "[x86-suite] path_open + fd_write + fd_close"
IOW_BIN="$TMP_DIR/io_write.bin"
build_bin "$ROOT_DIR/tests/x86_path_open_write_test.mee" "$IOW_BIN"
rm -f /tmp/mee_x86_io_test.txt
set +e
"$IOW_BIN" >/dev/null 2>&1
iow_rc=$?
set -e
assert_rc 3 "$iow_rc" "x86_path_open_write_test"
if [[ ! -f /tmp/mee_x86_io_test.txt ]]; then
  echo "[FAIL] x86_path_open_write_test: output file missing"
  exit 1
fi
if ! printf "OK\n" | cmp -s - /tmp/mee_x86_io_test.txt; then
  echo "[FAIL] x86_path_open_write_test: file contents mismatch"
  exit 1
fi
rm -f /tmp/mee_x86_io_test.txt

echo "[x86-suite] fd_read"
IOR_BIN="$TMP_DIR/io_read.bin"
build_bin "$ROOT_DIR/tests/x86_fd_read_test.mee" "$IOR_BIN"
set +e
printf "abcd" | "$IOR_BIN" >/dev/null 2>&1
ior_rc=$?
set -e
assert_rc 4 "$ior_rc" "x86_fd_read_test"

echo "[x86-suite] struct ABI"
SP_BIN="$TMP_DIR/struct_param_pass.bin"
build_bin "$ROOT_DIR/tests/struct_param_pass.mee" "$SP_BIN"
set +e
"$SP_BIN" >/dev/null 2>&1
sp_rc=$?
set -e
assert_rc 9 "$sp_rc" "struct_param_pass"

SR_BIN="$TMP_DIR/struct_return_basic.bin"
build_bin "$ROOT_DIR/tests/struct_return_basic.mee" "$SR_BIN"
set +e
"$SR_BIN" >/dev/null 2>&1
sr_rc=$?
set -e
assert_rc 15 "$sr_rc" "struct_return_basic"

SC_BIN="$TMP_DIR/struct_chain_calls.bin"
build_bin "$ROOT_DIR/tests/struct_chain_calls.mee" "$SC_BIN"
set +e
"$SC_BIN" >/dev/null 2>&1
sc_rc=$?
set -e
assert_rc 6 "$sc_rc" "struct_chain_calls"

echo "x86 runtime suite passed"
