#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[seed] regenerating converged self-host seed via check_self_compile.sh"
"$ROOT_DIR/selfhost/check_self_compile.sh"

cp /tmp/mee-bootstrap-stage1.wat "$ROOT_DIR/selfhost/bootstrap.seed.wat"
echo "[seed] updated selfhost/bootstrap.seed.wat"
