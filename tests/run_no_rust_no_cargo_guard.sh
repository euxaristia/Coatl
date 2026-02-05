#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-no-cargo-guard.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/cargo" <<'SH'
#!/usr/bin/env bash
echo "[FAIL] cargo should not be invoked in no-rust mode" >&2
exit 86
SH
chmod +x "$TMP_DIR/bin/cargo"

export PATH="$TMP_DIR/bin:$PATH"

COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_emit_full_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_asm_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_obj_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_ir_full_bin_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_wat_compile_default_seed_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_ir_emit_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_asm_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_auto_full_bin_compile_coverage.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_no_rust_bin_backend_parity_suite.sh"
COATL_NO_RUST=1 "$ROOT_DIR/tests/run_x86_path_open_edges_smoke.sh"

echo "no-rust no-cargo guard passed"
