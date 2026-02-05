#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-strict-no-rust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[strict-no-rust] cli no-rust smoke"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_cli_no_rust_smoke.sh"

echo "[strict-no-rust] selfhost no-rust ci"
MEE_NO_RUST=1 "$ROOT_DIR/selfhost/run_no_rust_ci.sh"

echo "[strict-no-rust] rust-backed emits must fail"
set +e
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=asm -o "$TMP_DIR/hello.s" >"$TMP_DIR/asm.out" 2>"$TMP_DIR/asm.err"
asm_rc=$?
set -e
if [[ "$asm_rc" -eq 0 ]]; then
  echo "[FAIL] expected --emit=asm to fail in strict no-rust mode"
  exit 1
fi
if ! grep -Fq "rust-disabled mode" "$TMP_DIR/asm.err"; then
  echo "[FAIL] missing rust-disabled error for --emit=asm"
  cat "$TMP_DIR/asm.err"
  exit 1
fi

set +e
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=ir -o "$TMP_DIR/hello.ir" >"$TMP_DIR/ir.out" 2>"$TMP_DIR/ir.err"
ir_rc=$?
set -e
if [[ "$ir_rc" -eq 0 ]]; then
  echo "[FAIL] expected --emit=ir to fail in strict no-rust mode"
  exit 1
fi
if ! grep -Fq "rust-disabled mode" "$TMP_DIR/ir.err"; then
  echo "[FAIL] missing rust-disabled error for --emit=ir"
  cat "$TMP_DIR/ir.err"
  exit 1
fi

echo "[strict-no-rust] toolchain=ir via non-Rust subset frontend"
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=wat --toolchain=ir -o "$TMP_DIR/hello-ir.wat"
if [[ ! -s "$TMP_DIR/hello-ir.wat" ]]; then
  echo "[FAIL] toolchain=ir did not produce WAT in strict mode"
  exit 1
fi
ir_out="$(wasmtime --invoke main "$TMP_DIR/hello-ir.wat")"
ir_ret="$(printf '%s\n' "$ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ir_ret" != "0" ]]; then
  echo "[FAIL] strict toolchain=ir run expected return 0 got $ir_ret"
  printf '%s\n' "$ir_out"
  exit 1
fi
if ! printf '%s\n' "$ir_out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] strict toolchain=ir output missing Hello, world!"
  printf '%s\n' "$ir_out"
  exit 1
fi

echo "[strict-no-rust] non-Rust IR lowerer lane"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_lowerer_smoke.sh"

echo "[strict-no-rust] centralized Rust entrypoint guard"
"$ROOT_DIR/tests/check_rust_entrypoint_centralization.sh"

echo "strict no-rust suite passed"
