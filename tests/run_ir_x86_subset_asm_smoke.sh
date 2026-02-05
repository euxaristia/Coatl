#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-x86-subset-asm.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
TOOLCHAIN="${MEE_ASM_TOOLCHAIN:-ir}"

if ! command -v gcc >/dev/null 2>&1; then
  echo "gcc is required but not found in PATH"
  exit 1
fi
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ir x86 subset asm smoke currently supports Linux only"
  exit 1
fi

build_bin() {
  local src="$1"
  local bin="$2"
  local asm="$TMP_DIR/$(basename "$bin").s"
  "$ROOT_DIR/mee" build "$src" --emit=asm --toolchain="$TOOLCHAIN" -o "$asm"
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

echo "[ir-x86-subset-asm] byte_test"
BYTE_BIN="$TMP_DIR/byte"
build_bin "$ROOT_DIR/tests/byte_test.mee" "$BYTE_BIN"
set +e
"$BYTE_BIN"
byte_rc=$?
set -e
assert_rc 133 "$byte_rc" "byte_test"

echo "[ir-x86-subset-asm] array_sim"
ARR_BIN="$TMP_DIR/array"
build_bin "$ROOT_DIR/tests/array_sim.mee" "$ARR_BIN"
set +e
"$ARR_BIN"
arr_rc=$?
set -e
assert_rc 100 "$arr_rc" "array_sim"

echo "[ir-x86-subset-asm] control_flow"
CF_BIN="$TMP_DIR/control"
build_bin "$ROOT_DIR/tests/ir_subset_control_flow.mee" "$CF_BIN"
set +e
"$CF_BIN"
cf_rc=$?
set -e
assert_rc 77 "$cf_rc" "ir_subset_control_flow"

echo "[ir-x86-subset-asm] struct chain"
STRUCT_BIN="$TMP_DIR/struct"
build_bin "$ROOT_DIR/tests/struct_chain_calls.mee" "$STRUCT_BIN"
set +e
"$STRUCT_BIN"
struct_rc=$?
set -e
assert_rc 6 "$struct_rc" "struct_chain_calls"

echo "[ir-x86-subset-asm] struct return basic"
SRB_BIN="$TMP_DIR/struct-return-basic"
build_bin "$ROOT_DIR/tests/struct_return_basic.mee" "$SRB_BIN"
set +e
"$SRB_BIN"
srb_rc=$?
set -e
assert_rc 15 "$srb_rc" "struct_return_basic"

echo "[ir-x86-subset-asm] struct param pass"
SPP_BIN="$TMP_DIR/struct-param"
build_bin "$ROOT_DIR/tests/struct_param_pass.mee" "$SPP_BIN"
set +e
"$SPP_BIN"
spp_rc=$?
set -e
assert_rc 9 "$spp_rc" "struct_param_pass"

echo "[ir-x86-subset-asm] struct field mutation"
SFM_BIN="$TMP_DIR/struct-mutate"
build_bin "$ROOT_DIR/tests/struct_field_mutation_subset.mee" "$SFM_BIN"
set +e
"$SFM_BIN"
sfm_rc=$?
set -e
assert_rc 33 "$sfm_rc" "struct_field_mutation_subset"

echo "[ir-x86-subset-asm] struct nested arg"
NEST_BIN="$TMP_DIR/struct-nested"
build_bin "$ROOT_DIR/tests/struct_nested_arg_subset.mee" "$NEST_BIN"
set +e
"$NEST_BIN"
nest_rc=$?
set -e
assert_rc 6 "$nest_rc" "struct_nested_arg_subset"

echo "[ir-x86-subset-asm] struct return if"
SIF_BIN="$TMP_DIR/struct-if"
build_bin "$ROOT_DIR/tests/struct_return_if_subset.mee" "$SIF_BIN"
set +e
"$SIF_BIN"
sif_rc=$?
set -e
assert_rc 36 "$sif_rc" "struct_return_if_subset"

echo "[ir-x86-subset-asm] struct return while"
SWH_BIN="$TMP_DIR/struct-while"
build_bin "$ROOT_DIR/tests/struct_return_while_subset.mee" "$SWH_BIN"
set +e
"$SWH_BIN"
swh_rc=$?
set -e
assert_rc 9 "$swh_rc" "struct_return_while_subset"

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

echo "[ir-x86-subset-asm] subset path_open/write/close"
SUBSET_IO_BIN="$TMP_DIR/subset-write"
build_bin "$ROOT_DIR/tests/ir_subset_path_open_write_close.mee" "$SUBSET_IO_BIN"
subset_dir="$TMP_DIR/subset-io"
mkdir -p "$subset_dir"
set +e
(
  cd "$subset_dir"
  "$SUBSET_IO_BIN"
)
subset_io_rc=$?
set -e
assert_rc 3 "$subset_io_rc" "ir_subset_path_open_write_close"
if [[ ! -f "$subset_dir/probe_out.txt" ]]; then
  echo "[FAIL] ir_subset_path_open_write_close missing probe_out.txt"
  exit 1
fi
if ! printf "OK\n" | cmp -s - "$subset_dir/probe_out.txt"; then
  echo "[FAIL] ir_subset_path_open_write_close file contents mismatch"
  cat "$subset_dir/probe_out.txt"
  exit 1
fi

echo "[ir-x86-subset-asm] path_open probe"
PROBE_BIN="$TMP_DIR/path-probe"
build_bin "$ROOT_DIR/tests/ir_subset_path_open_probe.mee" "$PROBE_BIN"
set +e
"$PROBE_BIN"
probe_rc=$?
set -e
assert_rc 0 "$probe_rc" "ir_subset_path_open_probe"
rm -f mee_probe.tmp

echo "ir x86 subset asm smoke suite passed"
