#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-aarch64-parity.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
source "$ROOT_DIR/tests/lib_aarch64_link.sh"

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi
if ! have_aarch64_link_toolchain; then
  echo "aarch64 link toolchain unavailable (need usable CC or as+ld)"
  exit 1
fi
if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "aarch64" ]]; then
  echo "aarch64 backend parity suite currently supports Linux aarch64 only"
  exit 1
fi

run_case() {
  local src="$1"
  local expected_rc="$2"
  local mode="${3:-}"
  local stdin_text="${4:-}"

  local stem
  stem="$(basename "$src" .coatl)"
  local wat="$TMP_DIR/$stem.wat"
  local asm="$TMP_DIR/$stem.s"
  local bin="$TMP_DIR/$stem.bin"

  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=ir -o "$wat"
  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=ir -o "$asm"
  link_aarch64_asm_binary "$asm" "$bin"

  local wat_out wat_proc_rc asm_out asm_rc
  if [[ "$mode" == "stdin" ]]; then
    set +e
    wat_out="$(printf '%s' "$stdin_text" | wasmtime --invoke main "$wat")"
    wat_proc_rc=$?
    asm_out="$(printf '%s' "$stdin_text" | "$bin")"
    asm_rc=$?
    set -e
  elif [[ "$mode" == "path_open_subset" ]]; then
    local io_dir="$TMP_DIR/${stem}_io"
    mkdir -p "$io_dir"
    set +e
    wat_out="$(wasmtime --dir "$io_dir" --invoke main "$wat")"
    wat_proc_rc=$?
    asm_out="$(cd "$io_dir" && "$bin")"
    asm_rc=$?
    set -e
    if [[ ! -f "$io_dir/probe_out.txt" ]]; then
      echo "[FAIL] $src missing probe_out.txt in parity run"
      exit 1
    fi
  else
    set +e
    wat_out="$(wasmtime --invoke main "$wat")"
    wat_proc_rc=$?
    asm_out="$("$bin")"
    asm_rc=$?
    set -e
  fi

  if [[ "$wat_proc_rc" != "0" ]]; then
    echo "[FAIL] $src WAT execution failed rc=$wat_proc_rc"
    printf '%s
' "$wat_out"
    exit 1
  fi

  local wat_ret
  wat_ret="$(printf '%s
' "$wat_out" | awk 'NF { line=$0 } END { print line }')"
  if [[ "$wat_ret" != "$expected_rc" ]]; then
    echo "[FAIL] $src WAT expected ret=$expected_rc got ret=$wat_ret"
    printf '%s
' "$wat_out"
    exit 1
  fi

  local asm_expected
  asm_expected=$(( expected_rc & 255 ))
  if [[ "$asm_rc" != "$asm_expected" ]]; then
    echo "[FAIL] $src ASM expected rc=$asm_expected (from ret=$expected_rc) got rc=$asm_rc"
    printf '%s
' "$asm_out"
    exit 1
  fi

  local wat_norm asm_norm
  wat_norm="$(printf '%s
' "$wat_out" | awk 'NF { lines[++n]=$0 } END { for(i=1;i<n;i++) print lines[i] }')"
  asm_norm="$(printf '%s
' "$asm_out" | sed '/^[[:space:]]*$/d')"
  if [[ "$wat_norm" != "$asm_norm" ]]; then
    echo "[FAIL] $src output mismatch between WAT and ASM backends"
    echo "--- wat ---"
    printf '%s
' "$wat_norm"
    echo "--- asm ---"
    printf '%s
' "$asm_norm"
    exit 1
  fi
  echo "  ok ($src rc=$expected_rc)"
}

echo "[aarch64-parity] hello"
run_case "examples/hello.coatl" "0"

echo "[aarch64-parity] mem/byte/array/control"
run_case "tests/mem_test.coatl" "142"
run_case "tests/byte_test.coatl" "389"
run_case "tests/array_sim.coatl" "100"
run_case "tests/ir_subset_control_flow.coatl" "77"

echo "aarch64 backend parity suite passed"
