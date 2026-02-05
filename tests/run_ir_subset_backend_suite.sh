#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-subset.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

check_case() {
  local src="$1"
  local expected="$2"
  local out_wat="$TMP_DIR/$(basename "$src" .coatl).wat"
  "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --emit=wat --toolchain=ir -o "$out_wat"
  local out
  out="$(wasmtime --invoke main "$out_wat")"
  local ret
  ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$ret" != "$expected" ]]; then
    echo "[FAIL] $src expected ret=$expected got ret=$ret"
    printf '%s\n' "$out"
    exit 1
  fi
  echo "  ok ($src => $expected)"
}

echo "[ir-subset] hello"
check_case "examples/hello.coatl" "0"

echo "[ir-subset] mem_test"
check_case "tests/mem_test.coatl" "142"

echo "[ir-subset] byte_test"
check_case "tests/byte_test.coatl" "389"

echo "[ir-subset] array_sim"
check_case "tests/array_sim.coatl" "100"

echo "[ir-subset] control_flow"
check_case "tests/ir_subset_control_flow.coatl" "77"

echo "[ir-subset] nested_let_scope_subset"
check_case "tests/nested_let_scope_subset.coatl" "7"

echo "[ir-subset] struct_param_pass"
check_case "tests/struct_param_pass.coatl" "9"

echo "[ir-subset] struct_return_basic"
check_case "tests/struct_return_basic.coatl" "15"

echo "[ir-subset] struct_chain_calls"
check_case "tests/struct_chain_calls.coatl" "6"

echo "[ir-subset] struct_field_mutation_subset"
check_case "tests/struct_field_mutation_subset.coatl" "33"

echo "[ir-subset] struct_nested_arg_subset"
check_case "tests/struct_nested_arg_subset.coatl" "6"

echo "[ir-subset] struct_return_if_subset"
check_case "tests/struct_return_if_subset.coatl" "36"

echo "[ir-subset] struct_return_while_subset"
check_case "tests/struct_return_while_subset.coatl" "9"

echo "ir subset backend suite passed"
