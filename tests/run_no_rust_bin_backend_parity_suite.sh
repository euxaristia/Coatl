#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-norust-bin-parity.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "no-rust bin backend parity suite currently supports Linux only"
  exit 1
fi

run_case() {
  local src="$1"
  local expected_rc="$2"
  local mode="${3:-}"
  local stdin_text="${4:-}"

  local stem
  stem="$(basename "$src" .mee)"
  local wat="$TMP_DIR/$stem.wat"
  local bin="$TMP_DIR/$stem.bin"

  MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/$src" --emit=wat --toolchain=ir -o "$wat"
  MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/$src" --emit=bin --toolchain=ir -o "$bin"

  local wat_out wat_proc_rc bin_out bin_rc
  if [[ "$mode" == "stdin" ]]; then
    set +e
    wat_out="$(printf '%s' "$stdin_text" | wasmtime --invoke main "$wat")"
    wat_proc_rc=$?
    bin_out="$(printf '%s' "$stdin_text" | "$bin")"
    bin_rc=$?
    set -e
  elif [[ "$mode" == "path_open_subset" ]]; then
    local io_dir="$TMP_DIR/${stem}_io"
    mkdir -p "$io_dir"
    set +e
    wat_out="$(wasmtime --dir "$io_dir" --invoke main "$wat")"
    wat_proc_rc=$?
    bin_out="$(cd "$io_dir" && "$bin")"
    bin_rc=$?
    set -e
    if [[ ! -f "$io_dir/probe_out.txt" ]]; then
      echo "[FAIL] $src missing probe_out.txt in parity run"
      exit 1
    fi
  else
    set +e
    wat_out="$(wasmtime --invoke main "$wat")"
    wat_proc_rc=$?
    bin_out="$("$bin")"
    bin_rc=$?
    set -e
  fi

  if [[ "$wat_proc_rc" != "0" ]]; then
    echo "[FAIL] $src WAT execution failed rc=$wat_proc_rc"
    printf '%s\n' "$wat_out"
    exit 1
  fi

  local wat_ret
  wat_ret="$(printf '%s\n' "$wat_out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$wat_ret" != "$expected_rc" ]]; then
    echo "[FAIL] $src WAT expected ret=$expected_rc got ret=$wat_ret"
    printf '%s\n' "$wat_out"
    exit 1
  fi

  local bin_expected
  bin_expected=$(( expected_rc & 255 ))
  if [[ "$bin_rc" != "$bin_expected" ]]; then
    echo "[FAIL] $src BIN expected rc=$bin_expected (from ret=$expected_rc) got rc=$bin_rc"
    printf '%s\n' "$bin_out"
    exit 1
  fi

  local wat_norm bin_norm
  wat_norm="$(printf '%s\n' "$wat_out" | awk 'NF { lines[++n]=$0 } END { for(i=1;i<n;i++) print lines[i] }')"
  bin_norm="$(printf '%s\n' "$bin_out" | sed '/^[[:space:]]*$/d')"
  if [[ "$wat_norm" != "$bin_norm" ]]; then
    echo "[FAIL] $src output mismatch between WAT and BIN backends"
    echo "--- wat ---"
    printf '%s\n' "$wat_norm"
    echo "--- bin ---"
    printf '%s\n' "$bin_norm"
    exit 1
  fi
  echo "  ok ($src rc=$expected_rc)"
}

echo "[no-rust-bin-parity] hello"
run_case "examples/hello.mee" "0"

echo "[no-rust-bin-parity] mem/byte/array/control"
run_case "tests/mem_test.mee" "142"
run_case "tests/byte_test.mee" "389"
run_case "tests/array_sim.mee" "100"
run_case "tests/ir_subset_control_flow.mee" "77"

echo "[no-rust-bin-parity] struct subset"
run_case "tests/struct_param_pass.mee" "9"
run_case "tests/struct_return_basic.mee" "15"
run_case "tests/struct_chain_calls.mee" "6"
run_case "tests/struct_field_mutation_subset.mee" "33"
run_case "tests/struct_nested_arg_subset.mee" "6"
run_case "tests/struct_return_if_subset.mee" "36"
run_case "tests/struct_return_while_subset.mee" "9"

echo "[no-rust-bin-parity] io"
run_case "tests/x86_fd_read_test.mee" "4" "stdin" "abcd"
run_case "tests/ir_subset_path_open_write_close.mee" "3" "path_open_subset"

echo "no-rust bin backend parity suite passed"
