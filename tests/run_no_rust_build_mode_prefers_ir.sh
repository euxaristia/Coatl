#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-no-rust-build-prefers-ir.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

out_wat="$TMP_DIR/control.wat"
out_err="$TMP_DIR/control.err"

COATL_IR_FIRST_BUILD=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/ir_subset_control_flow.coatl" --emit=wat -o "$out_wat" 2>"$out_err"

if grep -Fq "selfhost build failed" "$out_err"; then
  echo "[FAIL] no-rust-build mode should skip selfhost-first auto path"
  cat "$out_err"
  exit 1
fi
if grep -Fq "self-host compile" "$out_err"; then
  echo "[FAIL] no-rust-build mode should not invoke selfhost path"
  cat "$out_err"
  exit 1
fi

ret="$(wasmtime --invoke main "$out_wat" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "77" ]]; then
  echo "[FAIL] expected control-flow return 77 got $ret"
  exit 1
fi

echo "no-rust-build mode prefers ir pipeline passed"
