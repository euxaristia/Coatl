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
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=asm --toolchain=rust -o "$TMP_DIR/hello.s" >"$TMP_DIR/asm.out" 2>"$TMP_DIR/asm.err"
asm_rc=$?
set -e
if [[ "$asm_rc" -eq 0 ]]; then
  echo "[FAIL] expected --emit=asm --toolchain=rust to fail in strict no-rust mode"
  exit 1
fi
if ! grep -Fq "rust-disabled mode" "$TMP_DIR/asm.err"; then
  echo "[FAIL] missing rust-disabled error for --emit=asm --toolchain=rust"
  cat "$TMP_DIR/asm.err"
  exit 1
fi

echo "[strict-no-rust] emit=asm via toolchain=ir (subset asm backend)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_x86_subset_asm_smoke.sh"

echo "[strict-no-rust] emit=asm via toolchain=auto (subset asm fallback)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_auto_no_rust_asm_suite.sh"

echo "[strict-no-rust] x86 runtime suite via asm toolchain=ir"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_x86_runtime_suite_ir_no_rust.sh"

echo "[strict-no-rust] x86 runtime suite via asm toolchain=auto"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_x86_runtime_suite_auto_no_rust.sh"

set +e
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=ir --toolchain=rust -o "$TMP_DIR/hello.ir" >"$TMP_DIR/ir.out" 2>"$TMP_DIR/ir.err"
ir_rc=$?
set -e
if [[ "$ir_rc" -eq 0 ]]; then
  echo "[FAIL] expected --emit=ir --toolchain=rust to fail in strict no-rust mode"
  exit 1
fi
if ! grep -Fq "rust-disabled mode" "$TMP_DIR/ir.err"; then
  echo "[FAIL] missing rust-disabled error for --emit=ir --toolchain=rust"
  cat "$TMP_DIR/ir.err"
  exit 1
fi

echo "[strict-no-rust] emit=ir via toolchain=ir (subset frontend)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_frontend_smoke.sh"

echo "[strict-no-rust] emit=ir via toolchain=auto (subset frontend fallback)"
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=ir --toolchain=auto -o "$TMP_DIR/auto-ir.ir"
grep -Fq "(mee_ir v0" "$TMP_DIR/auto-ir.ir"
grep -Fq "(call __fd_write" "$TMP_DIR/auto-ir.ir"

echo "[strict-no-rust] toolchain=ir via non-Rust subset frontend"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_backend_suite.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (fd_read)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_io_smoke.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (path_open probe)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_path_open_smoke.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (path_open + fd_write + fd_close)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_path_open_write_close_smoke.sh"

echo "[strict-no-rust] struct support in no-rust mode (auto + ir subset)"
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/tests/struct_param_pass.mee" --emit=wat --toolchain=auto -o "$TMP_DIR/struct-auto.wat"
struct_auto_out="$(wasmtime --invoke main "$TMP_DIR/struct-auto.wat")"
struct_auto_ret="$(printf '%s\n' "$struct_auto_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_auto_ret" != "9" ]]; then
  echo "[FAIL] expected struct auto no-rust return 9 got $struct_auto_ret"
  printf '%s\n' "$struct_auto_out"
  exit 1
fi
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/tests/struct_param_pass.mee" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-ir.wat"
struct_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-ir.wat")"
struct_ir_ret="$(printf '%s\n' "$struct_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_ir_ret" != "9" ]]; then
  echo "[FAIL] expected struct ir no-rust return 9 got $struct_ir_ret"
  printf '%s\n' "$struct_ir_out"
  exit 1
fi

MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/tests/struct_return_basic.mee" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-ret-ir.wat"
struct_ret_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-ret-ir.wat")"
struct_ret_ir="$(printf '%s\n' "$struct_ret_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_ret_ir" != "15" ]]; then
  echo "[FAIL] expected struct return ir no-rust return 15 got $struct_ret_ir"
  printf '%s\n' "$struct_ret_ir_out"
  exit 1
fi

MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/tests/struct_chain_calls.mee" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-chain-ir.wat"
struct_chain_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-chain-ir.wat")"
struct_chain_ir="$(printf '%s\n' "$struct_chain_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_chain_ir" != "6" ]]; then
  echo "[FAIL] expected struct chain ir no-rust return 6 got $struct_chain_ir"
  printf '%s\n' "$struct_chain_ir_out"
  exit 1
fi

echo "[strict-no-rust] auto mode fallback: selfhost failure -> ir pipeline"
MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=wat --toolchain=auto --compiler /tmp/mee-missing-seed.wat -o "$TMP_DIR/auto-fallback.wat"
auto_out="$(wasmtime --invoke main "$TMP_DIR/auto-fallback.wat")"
auto_ret="$(printf '%s\n' "$auto_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$auto_ret" != "0" ]]; then
  echo "[FAIL] auto fallback expected return 0 got $auto_ret"
  printf '%s\n' "$auto_out"
  exit 1
fi
if ! printf '%s\n' "$auto_out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] auto fallback output missing Hello, world!"
  printf '%s\n' "$auto_out"
  exit 1
fi

echo "[strict-no-rust] auto mode fallback suite"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_auto_no_rust_fallback_suite.sh"

echo "[strict-no-rust] non-Rust IR lowerer lane"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_ir_lowerer_smoke.sh"

echo "[strict-no-rust] no-rust backend parity (wat vs asm)"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_backend_parity_suite.sh"

echo "[strict-no-rust] bootstrap compile via toolchain=ir"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_bootstrap_ir_compile.sh"

echo "[strict-no-rust] full no-rust toolchain=ir compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_compile_coverage.sh"

echo "[strict-no-rust] full no-rust emit=ir coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_emit_full_coverage.sh"

echo "[strict-no-rust] full no-rust toolchain=ir asm compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_asm_compile_coverage.sh"

echo "[strict-no-rust] full no-rust auto wat compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_coverage.sh"

echo "[strict-no-rust] full no-rust auto wat default-seed compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_default_seed_coverage.sh"

echo "[strict-no-rust] full no-rust auto emit=ir coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_ir_emit_coverage.sh"

echo "[strict-no-rust] full no-rust auto asm compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_asm_compile_coverage.sh"

echo "[strict-no-rust] no-rust no-cargo invocation guard"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_no_cargo_guard.sh"

echo "[strict-no-rust] full no-rust default-cli wat compile coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_wat_compile_coverage.sh"

echo "[strict-no-rust] full no-rust default-cli emit=ir coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_ir_emit_coverage.sh"

echo "[strict-no-rust] full no-rust default-cli emit=asm coverage"
MEE_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_asm_compile_coverage.sh"

echo "[strict-no-rust] centralized Rust entrypoint guard"
"$ROOT_DIR/tests/check_rust_entrypoint_centralization.sh"

echo "strict no-rust suite passed"
