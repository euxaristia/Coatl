#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-strict-no-rust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
source "$ROOT_DIR/tests/lib_x86_link.sh"
HAVE_C_COMPILER=0
if have_x86_link_toolchain; then
  HAVE_C_COMPILER=1
fi

echo "[strict-no-rust] cli no-rust smoke"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_cli_no_rust_smoke.sh"

echo "[strict-no-rust] selfhost bootstrap compile without C compiler"
"$ROOT_DIR/tests/run_no_c_compiler_selfhost_bootstrap_smoke.sh"

echo "[strict-no-rust] ir bin build without C compiler (as+ld path)"
"$ROOT_DIR/tests/run_no_rust_bin_ir_no_cc_smoke.sh"

echo "[strict-no-rust] selfhost no-rust ci"
COATL_NO_RUST=1 "$ROOT_DIR/selfhost/run_no_rust_ci.sh"

if [[ "$HAVE_C_COMPILER" -eq 1 ]]; then
  echo "[strict-no-rust] emit=asm via toolchain=ir (subset asm backend)"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_x86_subset_asm_smoke.sh"

  echo "[strict-no-rust] emit=asm via toolchain=auto (subset asm fallback)"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_auto_no_rust_asm_suite.sh"

  echo "[strict-no-rust] x86 runtime suite via asm toolchain=ir"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_x86_runtime_suite_ir_no_rust.sh"

  echo "[strict-no-rust] x86 runtime suite via asm toolchain=auto"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_x86_runtime_suite_auto_no_rust.sh"
else
  echo "[strict-no-rust] skip asm/x86 runtime checks: x86 link toolchain unavailable"
fi

echo "[strict-no-rust] x86 path_open edge cases"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_x86_path_open_edges_smoke.sh"

echo "[strict-no-rust] emit=ir via toolchain=ir (subset frontend)"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_frontend_smoke.sh"

echo "[strict-no-rust] emit=ir via toolchain=auto (subset frontend fallback)"
COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --emit=ir --toolchain=auto -o "$TMP_DIR/auto-ir.ir"
grep -Fq "(coatl_ir v0" "$TMP_DIR/auto-ir.ir"
grep -Fq "(call __fd_write" "$TMP_DIR/auto-ir.ir"

echo "[strict-no-rust] toolchain=ir via IR-based subset frontend"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_backend_suite.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (fd_read)"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_io_smoke.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (path_open probe)"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_path_open_smoke.sh"

echo "[strict-no-rust] toolchain=ir subset I/O (path_open + fd_write + fd_close)"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_subset_path_open_write_close_smoke.sh"

echo "[strict-no-rust] struct support in no-rust mode (auto + ir subset)"
COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/struct_param_pass.coatl" --emit=wat --toolchain=auto -o "$TMP_DIR/struct-auto.wat"
struct_auto_out="$(wasmtime --invoke main "$TMP_DIR/struct-auto.wat")"
struct_auto_ret="$(printf '%s\n' "$struct_auto_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_auto_ret" != "9" ]]; then
  echo "[FAIL] expected struct auto no-rust return 9 got $struct_auto_ret"
  printf '%s\n' "$struct_auto_out"
  exit 1
fi
COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/struct_param_pass.coatl" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-ir.wat"
struct_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-ir.wat")"
struct_ir_ret="$(printf '%s\n' "$struct_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_ir_ret" != "9" ]]; then
  echo "[FAIL] expected struct ir no-rust return 9 got $struct_ir_ret"
  printf '%s\n' "$struct_ir_out"
  exit 1
fi

COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/struct_return_basic.coatl" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-ret-ir.wat"
struct_ret_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-ret-ir.wat")"
struct_ret_ir="$(printf '%s\n' "$struct_ret_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_ret_ir" != "15" ]]; then
  echo "[FAIL] expected struct return ir no-rust return 15 got $struct_ret_ir"
  printf '%s\n' "$struct_ret_ir_out"
  exit 1
fi

COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/struct_chain_calls.coatl" --emit=wat --toolchain=ir -o "$TMP_DIR/struct-chain-ir.wat"
struct_chain_ir_out="$(wasmtime --invoke main "$TMP_DIR/struct-chain-ir.wat")"
struct_chain_ir="$(printf '%s\n' "$struct_chain_ir_out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$struct_chain_ir" != "6" ]]; then
  echo "[FAIL] expected struct chain ir no-rust return 6 got $struct_chain_ir"
  printf '%s\n' "$struct_chain_ir_out"
  exit 1
fi

echo "[strict-no-rust] auto mode fallback: selfhost failure -> ir pipeline"
COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --emit=wat --toolchain=auto --compiler /tmp/coatl-missing-seed.wat -o "$TMP_DIR/auto-fallback.wat"
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
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_auto_no_rust_fallback_suite.sh"

echo "[strict-no-rust] IR-based IR lowerer lane"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_ir_lowerer_smoke.sh"

echo "[strict-no-rust] tty intrinsic wiring and WASI graceful fallback"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_tty_intrinsics_smoke.sh"

if [[ "$HAVE_C_COMPILER" -eq 1 ]]; then
  echo "[strict-no-rust] no-rust backend parity (wat vs asm)"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_backend_parity_suite.sh"
else
  echo "[strict-no-rust] skip no-rust backend parity: x86 link toolchain unavailable"
fi

echo "[strict-no-rust] no-rust backend parity (wat vs bin)"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_bin_backend_parity_suite.sh"

echo "[strict-no-rust] bootstrap compile via toolchain=ir"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_bootstrap_ir_compile.sh"

echo "[strict-no-rust] full no-rust toolchain=ir compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_compile_coverage.sh"

echo "[strict-no-rust] full no-rust emit=ir coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_emit_full_coverage.sh"

echo "[strict-no-rust] full no-rust toolchain=ir asm compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_asm_compile_coverage.sh"

echo "[strict-no-rust] full no-rust toolchain=ir obj compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_obj_compile_coverage.sh"

echo "[strict-no-rust] full no-rust toolchain=ir bin compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_bin_compile_coverage.sh"

echo "[strict-no-rust] full no-rust auto wat compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_coverage.sh"

echo "[strict-no-rust] full no-rust auto wat default-seed compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_default_seed_coverage.sh"

echo "[strict-no-rust] full no-rust auto emit=ir coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_ir_emit_coverage.sh"

echo "[strict-no-rust] full no-rust auto asm compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_asm_compile_coverage.sh"

echo "[strict-no-rust] full no-rust auto bin compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_bin_compile_coverage.sh"

echo "[strict-no-rust] no-rust no-cargo invocation guard"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_no_cargo_guard.sh"

echo "[strict-no-rust] full no-rust default-cli wat compile coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_wat_compile_coverage.sh"

echo "[strict-no-rust] full no-rust default-cli emit=ir coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_ir_emit_coverage.sh"

echo "[strict-no-rust] full no-rust default-cli emit=asm coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_asm_compile_coverage.sh"

echo "[strict-no-rust] full no-rust default-cli emit=bin coverage"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_full_bin_compile_coverage.sh"

if [[ "$HAVE_C_COMPILER" -eq 1 ]]; then
  echo "[strict-no-rust] default-cli no-rust backend parity (wat vs asm)"
  COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_default_cli_backend_parity_suite.sh"
else
  echo "[strict-no-rust] skip default-cli backend parity: x86 link toolchain unavailable"
fi

echo "[strict-no-rust] no-rust-build mode full coverage"
"$ROOT_DIR/tests/run_no_rust_build_mode_full_coverage.sh"

echo "[strict-no-rust] no-rust-build mode prefers ir pipeline in auto"
"$ROOT_DIR/tests/run_no_rust_build_mode_prefers_ir.sh"

echo "[strict-no-rust] no-rust-build works without compiler directory"
"$ROOT_DIR/tests/run_no_rust_build_without_compiler_dir.sh"

echo "strict no-rust suite passed"
