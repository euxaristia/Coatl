#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BOOTSTRAP_SRC="$ROOT_DIR/selfhost/bootstrap.mee"
STAGE0_WAT="/tmp/mee-bootstrap-stage0.wat"
STAGE0_STDIN_WAT="/tmp/mee-bootstrap-stage0-stdin.wat"
STAGE1_RAW="/tmp/mee-bootstrap-stage1.raw"
STAGE1_WAT="/tmp/mee-bootstrap-stage1.wat"
STAGE1_STDIN_WAT="/tmp/mee-bootstrap-stage1-stdin.wat"
STAGE2_RAW="/tmp/mee-bootstrap-stage2.raw"
STAGE2_WAT="/tmp/mee-bootstrap-stage2.wat"

patch_stdin_flag() {
  local in_wat="$1"
  local out_wat="$2"
  python3 - "$in_wat" "$out_wat" <<'PY'
from pathlib import Path
import sys
src_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
state_stdin_flag = 18874412  # state_base + 44
src = src_path.read_text(errors='ignore')
needle = f'(data (i32.const {state_stdin_flag}) "\\01")'
if needle not in src:
    src = src.replace('(memory', f'  {needle}\n  (memory', 1)
out_path.write_text(src)
PY
}

clean_wat_output() {
  local in_raw="$1"
  local out_wat="$2"
  python3 - "$in_raw" "$out_wat" <<'PY'
from pathlib import Path
import sys
raw = Path(sys.argv[1]).read_bytes()
if b'\x00' in raw:
    raw = raw.split(b'\x00', 1)[0]
raw = raw.rstrip(b'\r\n\t ') + b'\n'
Path(sys.argv[2]).write_bytes(raw)
PY
}

echo "[1/6] Building stage0 WAT with Rust compiler"
(
  cd "$ROOT_DIR/compiler"
  cargo run --quiet -- build ../selfhost/bootstrap.mee --emit=wat -o "$STAGE0_WAT"
)

echo "[2/6] Running stage0 -> stage1"
patch_stdin_flag "$STAGE0_WAT" "$STAGE0_STDIN_WAT"
wasmtime --invoke main "$STAGE0_STDIN_WAT" < "$BOOTSTRAP_SRC" > "$STAGE1_RAW"
clean_wat_output "$STAGE1_RAW" "$STAGE1_WAT"

echo "[3/6] Sanity-check stage1"
stage1_rc=$(wasmtime --invoke main "$STAGE1_WAT" | tr -d '[:space:]')
if [[ "$stage1_rc" != "0" ]]; then
  echo "stage1 returned $stage1_rc (expected 0)"
  exit 1
fi

echo "[4/6] Running stage1 -> stage2"
patch_stdin_flag "$STAGE1_WAT" "$STAGE1_STDIN_WAT"
wasmtime --invoke main "$STAGE1_STDIN_WAT" < "$BOOTSTRAP_SRC" > "$STAGE2_RAW"
clean_wat_output "$STAGE2_RAW" "$STAGE2_WAT"

echo "[5/6] Sanity-check stage2"
stage2_rc=$(wasmtime --invoke main "$STAGE2_WAT" | tr -d '[:space:]')
if [[ "$stage2_rc" != "0" ]]; then
  echo "stage2 returned $stage2_rc (expected 0)"
  exit 1
fi

echo "[6/6] Checking convergence"
if cmp -s "$STAGE1_WAT" "$STAGE2_WAT"; then
  sha256sum "$STAGE1_WAT" "$STAGE2_WAT"
  echo "OK: self-compile converged"
else
  echo "ERROR: stage1 and stage2 outputs differ"
  diff -u "$STAGE1_WAT" "$STAGE2_WAT" | sed -n '1,80p'
  exit 1
fi
