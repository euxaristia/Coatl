#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-x86-suite.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
TOOLCHAIN="${COATL_X86_TOOLCHAIN:-ir}"
source "$ROOT_DIR/tests/lib_x86_link.sh"

RUNNER=()
EMULATED=0

detect_qemu_prefix_from_cc() {
  local cc="$1"
  local libc_path=""
  if [[ -n "$cc" ]] && command -v "$cc" >/dev/null 2>&1; then
    libc_path="$("$cc" -print-file-name=libc.so.6 2>/dev/null || true)"
  fi
  if [[ -z "$libc_path" || "$libc_path" == "libc.so.6" ]]; then
    if command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
      libc_path="$(x86_64-linux-gnu-gcc -print-file-name=libc.so.6 2>/dev/null || true)"
    fi
  fi
  if [[ -n "$libc_path" && "$libc_path" != "libc.so.6" ]]; then
    dirname "$(dirname "$libc_path")"
  fi
}

run_bin() {
  if [[ "${#RUNNER[@]}" -gt 0 ]]; then
    "${RUNNER[@]}" "$@"
  else
    "$@"
  fi
}
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "x86 runtime suite currently supports Linux only"
  exit 1
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  if command -v qemu-x86_64 >/dev/null 2>&1; then
    RUNNER=("qemu-x86_64")
    EMULATED=1
    echo "[x86-suite] Using qemu-x86_64 for execution"
  else
    echo "x86 runtime suite requires x86_64 host or qemu-x86_64"
    exit 1
  fi
  # If CC is not set and we are cross-compiling, try to find a cross-compiler
  if [[ -z "${CC:-}" ]] && command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
    export CC=x86_64-linux-gnu-gcc
    echo "[x86-suite] Using $CC for linking"
  fi
  qemu_prefix="${QEMU_LD_PREFIX:-}"
  if [[ -z "$qemu_prefix" ]]; then
    qemu_prefix="$(detect_qemu_prefix_from_cc "${CC:-}")"
  fi
  if [[ -n "$qemu_prefix" ]]; then
    RUNNER+=("-L" "$qemu_prefix")
    echo "[x86-suite] Using qemu sysroot: $qemu_prefix"
  fi
fi

if ! have_x86_link_toolchain; then
  echo "x86 runtime suite requires usable CC or as+ld"
  exit 1
fi

build_bin() {
  local src="$1"
  local out="$2"
  local asm="$TMP_DIR/$(basename "$out").s"
  "$ROOT_DIR/coatl" build "$src" --arch=x86_64 --toolchain="$TOOLCHAIN" -o "$asm"
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
build_bin "$ROOT_DIR/examples/hello.coatl" "$HELLO_BIN"
hello_out="$(run_bin "$HELLO_BIN")"
hello_rc=$?
if ! printf '%s\n' "$hello_out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] hello output mismatch"
  printf 'got: %q\n' "$hello_out"
  echo "$hello_out" | xxd
  exit 1
fi
assert_rc 0 "$hello_rc" "hello"

echo "[x86-suite] mem intrinsics"
MEM_BIN="$TMP_DIR/mem.bin"
build_bin "$ROOT_DIR/tests/mem_test.coatl" "$MEM_BIN"
set +e
run_bin "$MEM_BIN" >/dev/null 2>&1
mem_rc=$?
set -e
assert_rc 142 "$mem_rc" "mem_test"

echo "[x86-suite] path_open + fd_write + fd_close"
IOW_BIN="$TMP_DIR/io_write.bin"
build_bin "$ROOT_DIR/tests/x86_path_open_write_test.coatl" "$IOW_BIN"
if [[ "$EMULATED" -eq 1 ]]; then
  echo "[x86-suite] Skipping x86_path_open_write_test under qemu-x86_64"
else
  rm -f /tmp/coatl_x86_io_test.txt
  set +e
  run_bin "$IOW_BIN" >/dev/null 2>&1
  iow_rc=$?
  set -e
  assert_rc 3 "$iow_rc" "x86_path_open_write_test"
  if [[ ! -f /tmp/coatl_x86_io_test.txt ]]; then
    echo "[FAIL] x86_path_open_write_test: output file missing"
    exit 1
  fi
  if ! printf "OK\n" | cmp -s - /tmp/coatl_x86_io_test.txt; then
    echo "[FAIL] x86_path_open_write_test: file contents mismatch"
    exit 1
  fi
  rm -f /tmp/coatl_x86_io_test.txt
fi

echo "[x86-suite] fd_read"
IOR_BIN="$TMP_DIR/io_read.bin"
build_bin "$ROOT_DIR/tests/x86_fd_read_test.coatl" "$IOR_BIN"
if [[ "$EMULATED" -eq 1 ]]; then
  echo "[x86-suite] Skipping x86_fd_read_test under qemu-x86_64"
else
  set +e
  printf "abcd" | run_bin "$IOR_BIN" >/dev/null 2>&1
  ior_rc=$?
  set -e
  assert_rc 4 "$ior_rc" "x86_fd_read_test"
fi

echo "[x86-suite] struct ABI"
SP_BIN="$TMP_DIR/struct_param_pass.bin"
build_bin "$ROOT_DIR/tests/struct_param_pass.coatl" "$SP_BIN"
set +e
run_bin "$SP_BIN" >/dev/null 2>&1
sp_rc=$?
set -e
assert_rc 9 "$sp_rc" "struct_param_pass"

SR_BIN="$TMP_DIR/struct_return_basic.bin"
build_bin "$ROOT_DIR/tests/struct_return_basic.coatl" "$SR_BIN"
set +e
run_bin "$SR_BIN" >/dev/null 2>&1
sr_rc=$?
set -e
assert_rc 15 "$sr_rc" "struct_return_basic"

SC_BIN="$TMP_DIR/struct_chain_calls.bin"
build_bin "$ROOT_DIR/tests/struct_chain_calls.coatl" "$SC_BIN"
set +e
run_bin "$SC_BIN" >/dev/null 2>&1
sc_rc=$?
set -e
assert_rc 6 "$sc_rc" "struct_chain_calls"

echo "x86 runtime suite passed"
