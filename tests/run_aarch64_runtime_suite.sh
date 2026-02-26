#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-aarch64-suite.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
TOOLCHAIN="${COATL_AARCH64_TOOLCHAIN:-ir}"
source "$ROOT_DIR/tests/lib_aarch64_link.sh"

RUNNER=()

detect_qemu_prefix_from_cc() {
  local cc="$1"
  local libc_path=""
  if [[ -n "$cc" ]] && command -v "$cc" >/dev/null 2>&1; then
    libc_path="$("$cc" -print-file-name=libc.so.6 2>/dev/null || true)"
  fi
  if [[ -z "$libc_path" || "$libc_path" == "libc.so.6" ]]; then
    if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
      libc_path="$(aarch64-linux-gnu-gcc -print-file-name=libc.so.6 2>/dev/null || true)"
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
  echo "aarch64 runtime suite currently supports Linux only"
  exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
  if command -v qemu-aarch64 >/dev/null 2>&1; then
    RUNNER=("qemu-aarch64")
    echo "[aarch64-suite] Using qemu-aarch64 for execution"
  else
    echo "aarch64 runtime suite requires aarch64 host or qemu-aarch64"
    exit 1
  fi
  # If CC is not set and we are cross-compiling, try to find a cross-compiler
  if [[ -z "${CC:-}" ]] && command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    export CC=aarch64-linux-gnu-gcc
    echo "[aarch64-suite] Using $CC for linking"
  fi
  qemu_prefix="${QEMU_LD_PREFIX:-}"
  if [[ -z "$qemu_prefix" ]]; then
    qemu_prefix="$(detect_qemu_prefix_from_cc "${CC:-}")"
  fi
  if [[ -n "$qemu_prefix" ]]; then
    RUNNER+=("-L" "$qemu_prefix")
    echo "[aarch64-suite] Using qemu sysroot: $qemu_prefix"
  fi
fi

if ! have_aarch64_link_toolchain; then
  echo "aarch64 runtime suite requires usable CC or as+ld"
  exit 1
fi

build_bin() {
  local src="$1"
  local out="$2"
  local asm="$TMP_DIR/$(basename "$out").s"
  "$ROOT_DIR/coatl" build "$src" --arch=aarch64 --toolchain="$TOOLCHAIN" -o "$asm"
  link_aarch64_asm_binary "$asm" "$out"
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

assert_any_rc() {
  local allowed="$1"
  local got="$2"
  local name="$3"
  local rc
  for rc in $allowed; do
    if [[ "$got" -eq "$rc" ]]; then
      return 0
    fi
  done
  echo "[FAIL] $name: expected rc in {$allowed} got rc=$got"
  exit 1
}

echo "[aarch64-suite] mem_test"
MEM_BIN="$TMP_DIR/mem.bin"
build_bin "$ROOT_DIR/tests/mem_test.coatl" "$MEM_BIN"
set +e
run_bin "$MEM_BIN" >/dev/null 2>&1
mem_rc=$?
set -e
assert_rc 142 "$mem_rc" "mem_test"

echo "[aarch64-suite] byte_test"
BYTE_BIN="$TMP_DIR/byte.bin"
build_bin "$ROOT_DIR/tests/byte_test.coatl" "$BYTE_BIN"
set +e
run_bin "$BYTE_BIN" >/dev/null 2>&1
byte_rc=$?
set -e
assert_any_rc "133 173" "$byte_rc" "byte_test"

echo "[aarch64-suite] array_sim"
ARR_BIN="$TMP_DIR/array.bin"
build_bin "$ROOT_DIR/tests/array_sim.coatl" "$ARR_BIN"
set +e
run_bin "$ARR_BIN" >/dev/null 2>&1
arr_rc=$?
set -e
assert_any_rc "100 60" "$arr_rc" "array_sim"

echo "[aarch64-suite] control_flow"
CF_BIN="$TMP_DIR/control.bin"
build_bin "$ROOT_DIR/tests/ir_subset_control_flow.coatl" "$CF_BIN"
set +e
run_bin "$CF_BIN" >/dev/null 2>&1
cf_rc=$?
set -e
assert_rc 77 "$cf_rc" "ir_subset_control_flow"

echo "aarch64 runtime suite passed"
