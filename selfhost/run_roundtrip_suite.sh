#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE="selfhost"
if [[ "${1:-}" == "--with-rust" ]]; then
  MODE="rust"
fi

if [[ "$MODE" == "selfhost" ]]; then
  exec "$ROOT_DIR/selfhost/run_roundtrip_suite_seed.sh"
fi

SELFHOST_CHECK="$ROOT_DIR/selfhost/check_self_compile.sh"
STAGE1_WAT="/tmp/mee-bootstrap-stage1.wat"
STAGE1_STDIN_WAT="/tmp/mee-bootstrap-stage1-stdin.wat"

patch_stdin_flag() {
  local in_wat="$1"
  local out_wat="$2"
  python3 - "$in_wat" "$out_wat" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1]).read_text(errors='ignore')
flag = 18874412  # state_base + 44
needle = f'(data (i32.const {flag}) "\\01")'
if needle not in src:
    src = src.replace('(memory', f'  {needle}\n  (memory', 1)
Path(sys.argv[2]).write_text(src)
PY
}

clean_compiler_output() {
  local in_raw="$1"
  local out_wat="$2"
  python3 - "$in_raw" "$out_wat" <<'PY'
from pathlib import Path
import sys
raw = Path(sys.argv[1]).read_bytes()
if b'\x00' in raw:
    raw = raw.split(b'\x00', 1)[0]
text = raw.rstrip(b'\r\n\t ') + b'\n'
Path(sys.argv[2]).write_bytes(text)
PY
}

run_and_get_return() {
  local wat="$1"
  local out
  out=$(wasmtime --invoke main "$wat")
  local ret
  ret=$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')
  printf '%s\n' "$out" > /tmp/mee-last-run.txt
  printf '%s\n' "$ret"
}

compile_with_selfhost() {
  local src="$1"
  local out_wat="$2"
  local raw="${out_wat}.raw"
  local lowered="${out_wat}.lowered.mee"
  python3 "$ROOT_DIR/selfhost/lower_structs.py" "$src" "$lowered"
  wasmtime --invoke main "$STAGE1_STDIN_WAT" < "$lowered" > "$raw"
  clean_compiler_output "$raw" "$out_wat"
  if ! head -n 1 "$out_wat" | grep -q "^(module"; then
    echo "selfhost compile did not produce WAT for $src"
    tail -n 20 "$raw"
    exit 1
  fi
}

compile_with_rust() {
  local src="$1"
  local out_wat="$2"
  (
    cd "$ROOT_DIR/compiler"
    cargo run --quiet -- build "../$src" --emit=wat -o "$out_wat"
  )
}

check_case() {
  local src="$1"
  local expected_ret="$2"
  local expect_substr="${3:-}"
  local base
  base=$(basename "$src" .mee)
  local self_wat="/tmp/mee-self-${base}.wat"
  local rust_wat="/tmp/mee-rust-${base}.wat"

  echo "[case] $src"
  compile_with_selfhost "$ROOT_DIR/$src" "$self_wat"
  compile_with_rust "$src" "$rust_wat"

  local self_out
  local rust_out
  self_out=$(wasmtime --invoke main "$self_wat")
  rust_out=$(wasmtime --invoke main "$rust_wat")

  local self_ret
  local rust_ret
  self_ret=$(printf '%s\n' "$self_out" | awk 'NF { line=$0 } END { print line }')
  rust_ret=$(printf '%s\n' "$rust_out" | awk 'NF { line=$0 } END { print line }')

  if [[ "$self_ret" != "$expected_ret" ]]; then
    echo "selfhost return mismatch for $src: got $self_ret expected $expected_ret"
    printf '%s\n' "$self_out"
    exit 1
  fi
  if [[ "$rust_ret" != "$expected_ret" ]]; then
    echo "rust return mismatch for $src: got $rust_ret expected $expected_ret"
    printf '%s\n' "$rust_out"
    exit 1
  fi
  if [[ "$self_ret" != "$rust_ret" ]]; then
    echo "return mismatch between compilers for $src: selfhost=$self_ret rust=$rust_ret"
    exit 1
  fi

  if [[ -n "$expect_substr" ]]; then
    if ! printf '%s\n' "$self_out" | grep -Fq "$expect_substr"; then
      echo "selfhost output missing expected text for $src: $expect_substr"
      printf '%s\n' "$self_out"
      exit 1
    fi
    if ! printf '%s\n' "$rust_out" | grep -Fq "$expect_substr"; then
      echo "rust output missing expected text for $src: $expect_substr"
      printf '%s\n' "$rust_out"
      exit 1
    fi
  fi

  echo "  ok (return=$expected_ret)"
}

echo "[roundtrip] Verifying self-compile convergence"
"$SELFHOST_CHECK"

if [[ ! -f "$STAGE1_WAT" ]]; then
  echo "missing $STAGE1_WAT"
  exit 1
fi

patch_stdin_flag "$STAGE1_WAT" "$STAGE1_STDIN_WAT"

echo "[roundtrip] Running runtime suite"
check_case "tests/mem_test.mee" "142"
check_case "tests/array_sim.mee" "100"
check_case "tests/byte_test.mee" "389"
check_case "examples/hello.mee" "0" "Hello, world!"

echo "[roundtrip] Running struct ABI suite"
check_case "tests/struct_param_pass.mee" "9"
check_case "tests/struct_return_basic.mee" "15"
check_case "tests/struct_chain_calls.mee" "6"

echo "All round-trip checks passed"
