#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-auto-norust-fallback.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

MISSING_SEED="/tmp/coatl-missing-seed.wat"

check_case() {
  local src="$1"
  local expected="$2"
  local out_wat="$TMP_DIR/$(basename "$src" .coatl).wat"
  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=auto --compiler "$MISSING_SEED" -o "$out_wat"
  local out
  out="$(wasmtime --invoke main "$out_wat")"
  local ret
  ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$ret" != "$expected" ]]; then
    echo "[FAIL] auto fallback $src expected ret=$expected got ret=$ret"
    printf '%s\n' "$out"
    exit 1
  fi
  echo "  ok ($src => $expected)"
}

check_case_stdin() {
  local src="$1"
  local expected="$2"
  local stdin_text="$3"
  local out_wat="$TMP_DIR/$(basename "$src" .coatl).wat"
  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=auto --compiler "$MISSING_SEED" -o "$out_wat"
  local out
  out="$(printf '%s' "$stdin_text" | wasmtime --invoke main "$out_wat")"
  local ret
  ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$ret" != "$expected" ]]; then
    echo "[FAIL] auto fallback $src expected ret=$expected got ret=$ret"
    printf '%s\n' "$out"
    exit 1
  fi
  echo "  ok ($src => $expected, stdin)"
}

check_case_path_open_write_close() {
  local src="$1"
  local expected="$2"
  local out_wat="$TMP_DIR/$(basename "$src" .coatl).wat"
  local out_file="$TMP_DIR/probe_out.txt"
  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=auto --compiler "$MISSING_SEED" -o "$out_wat"
  local out
  out="$(wasmtime --dir "$TMP_DIR" --invoke main "$out_wat")"
  local ret
  ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$ret" != "$expected" ]]; then
    echo "[FAIL] auto fallback $src expected ret=$expected got ret=$ret"
    printf '%s\n' "$out"
    exit 1
  fi
  if [[ ! -f "$out_file" ]]; then
    echo "[FAIL] auto fallback $src expected output file $out_file"
    exit 1
  fi
  if ! printf "OK\n" | cmp -s - "$out_file"; then
    echo "[FAIL] auto fallback $src file contents mismatch"
    cat "$out_file"
    exit 1
  fi
  echo "  ok ($src => $expected, path_open/write/close)"
}

echo "[auto-no-rust-fallback] hello"
check_case "examples/hello.coatl" "0"

echo "[auto-no-rust-fallback] mem_test"
check_case "tests/mem_test.coatl" "142"

echo "[auto-no-rust-fallback] control_flow"
check_case "tests/ir_subset_control_flow.coatl" "77"

echo "[auto-no-rust-fallback] struct_param_pass"
check_case "tests/struct_param_pass.coatl" "9"

echo "[auto-no-rust-fallback] struct_return_basic"
check_case "tests/struct_return_basic.coatl" "15"

echo "[auto-no-rust-fallback] struct_chain_calls"
check_case "tests/struct_chain_calls.coatl" "6"

echo "[auto-no-rust-fallback] struct_field_mutation_subset"
check_case "tests/struct_field_mutation_subset.coatl" "33"

echo "[auto-no-rust-fallback] struct_nested_arg_subset"
check_case "tests/struct_nested_arg_subset.coatl" "6"

echo "[auto-no-rust-fallback] struct_return_if_subset"
check_case "tests/struct_return_if_subset.coatl" "36"

echo "[auto-no-rust-fallback] struct_return_while_subset"
check_case "tests/struct_return_while_subset.coatl" "9"

echo "[auto-no-rust-fallback] fd_read"
check_case_stdin "tests/x86_fd_read_test.coatl" "4" "abcd"

echo "[auto-no-rust-fallback] path_open+write+close"
check_case_path_open_write_close "tests/ir_subset_path_open_write_close.coatl" "3"

echo "auto no-rust fallback suite passed"
