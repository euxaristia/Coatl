#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_SRC="$ROOT_DIR/selfhost/bootstrap.coatl"
SEED_WAT="$ROOT_DIR/selfhost/bootstrap.seed.wat"
source "$ROOT_DIR/selfhost/wat_utils.sh"
SEED_STDIN_WAT="/tmp/coatl-bootstrap-seed-stdin.wat"
STAGE1_RAW="/tmp/coatl-bootstrap-seed-stage1.raw"
STAGE1_WAT="/tmp/coatl-bootstrap-seed-stage1.wat"
STAGE1_STDIN_WAT="/tmp/coatl-bootstrap-seed-stage1-stdin.wat"
STAGE2_RAW="/tmp/coatl-bootstrap-seed-stage2.raw"
STAGE2_WAT="/tmp/coatl-bootstrap-seed-stage2.wat"

if [[ ! -f "$SEED_WAT" ]]; then
  echo "missing seed compiler: $SEED_WAT"
  exit 1
fi
if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[1/5] Running seed -> stage1"
patch_stdin_flag "$SEED_WAT" "$SEED_STDIN_WAT"
wasmtime --invoke main "$SEED_STDIN_WAT" < "$BOOTSTRAP_SRC" > "$STAGE1_RAW"
clean_wat_output "$STAGE1_RAW" "$STAGE1_WAT"

echo "[2/5] Sanity-check stage1"
stage1_rc=$(wasmtime --invoke main "$STAGE1_WAT" | tr -d '[:space:]')
if [[ "$stage1_rc" != "0" ]]; then
  echo "stage1 returned $stage1_rc (expected 0)"
  exit 1
fi

echo "[3/5] Running stage1 -> stage2"
patch_stdin_flag "$STAGE1_WAT" "$STAGE1_STDIN_WAT"
wasmtime --invoke main "$STAGE1_STDIN_WAT" < "$BOOTSTRAP_SRC" > "$STAGE2_RAW"
clean_wat_output "$STAGE2_RAW" "$STAGE2_WAT"

echo "[4/5] Sanity-check stage2"
stage2_rc=$(wasmtime --invoke main "$STAGE2_WAT" | tr -d '[:space:]')
if [[ "$stage2_rc" != "0" ]]; then
  echo "stage2 returned $stage2_rc (expected 0)"
  exit 1
fi

echo "[5/5] Checking convergence"
if cmp -s "$STAGE1_WAT" "$STAGE2_WAT"; then
  sha256sum "$STAGE1_WAT" "$STAGE2_WAT"
  echo "OK: self-compile converged (seed-only)"
else
  echo "ERROR: stage1 and stage2 outputs differ"
  diff -u "$STAGE1_WAT" "$STAGE2_WAT" | sed -n '1,80p'
  exit 1
fi
