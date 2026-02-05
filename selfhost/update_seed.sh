#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE="selfhost"
if [[ "${1:-}" == "--with-rust" ]]; then
  MODE="rust"
fi

if [[ "$MODE" == "rust" ]]; then
  echo "[seed] regenerating converged self-host seed via Rust-assisted chain"
  "$ROOT_DIR/selfhost/check_self_compile.sh"
  cp /tmp/mee-bootstrap-stage1.wat "$ROOT_DIR/selfhost/bootstrap.seed.wat"
else
  echo "[seed] regenerating converged self-host seed via seed-only chain (no Rust)"
  "$ROOT_DIR/selfhost/check_self_compile_seed.sh"
  cp /tmp/mee-bootstrap-seed-stage1.wat "$ROOT_DIR/selfhost/bootstrap.seed.wat"
fi

echo "[seed] updated selfhost/bootstrap.seed.wat"
