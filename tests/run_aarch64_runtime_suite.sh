#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-aarch64-suite.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
TOOLCHAIN="${COATL_AARCH64_TOOLCHAIN:-ir}"
source "$ROOT_DIR/tests/lib_aarch64_link.sh"

RUNNER=""
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "aarch64 runtime suite currently supports Linux only"
  exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
  if command -v qemu-aarch64 >/dev/null 2>&1; then
    RUNNER="qemu-aarch64"
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

echo "[aarch64-suite] mem_test"
MEM_BIN="$TMP_DIR/mem.bin"
build_bin "$ROOT_DIR/tests/mem_test.coatl" "$MEM_BIN"
set +e
$RUNNER "$MEM_BIN" >/dev/null 2>&1
mem_rc=$?
set -e
assert_rc 142 "$mem_rc" "mem_test"

echo "[aarch64-suite] byte_test"
BYTE_BIN="$TMP_DIR/byte.bin"
build_bin "$ROOT_DIR/tests/byte_test.coatl" "$BYTE_BIN"
set +e
$RUNNER "$BYTE_BIN" >/dev/null 2>&1
byte_rc=$?
set -e
assert_rc 133 "$byte_rc" "byte_test"

echo "[aarch64-suite] array_sim"
ARR_BIN="$TMP_DIR/array.bin"
build_bin "$ROOT_DIR/tests/array_sim.coatl" "$ARR_BIN"
set +e
$RUNNER "$ARR_BIN" >/dev/null 2>&1
arr_rc=$?
set -e
assert_rc 100 "$arr_rc" "array_sim"

echo "[aarch64-suite] control_flow"
CF_BIN="$TMP_DIR/control.bin"
build_bin "$ROOT_DIR/tests/ir_subset_control_flow.coatl" "$CF_BIN"
set +e
$RUNNER "$CF_BIN" >/dev/null 2>&1
cf_rc=$?
set -e
assert_rc 77 "$cf_rc" "ir_subset_control_flow"

echo "aarch64 runtime suite passed"
