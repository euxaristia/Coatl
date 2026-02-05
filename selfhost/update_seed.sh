#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[seed] regenerating converged self-host seed via seed-only chain"
"$ROOT_DIR/selfhost/check_self_compile_seed.sh"
cp /tmp/coatl-bootstrap-seed-stage1.wat "$ROOT_DIR/selfhost/bootstrap.seed.wat"

echo "[seed] updated selfhost/bootstrap.seed.wat"
