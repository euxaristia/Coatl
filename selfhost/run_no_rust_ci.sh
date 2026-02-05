#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[no-rust] self-compile convergence"
"$ROOT_DIR/selfhost/check_self_compile.sh"

echo "[no-rust] roundtrip runtime suite"
"$ROOT_DIR/selfhost/run_roundtrip_suite.sh"

echo "[no-rust] refresh seed from seed chain"
"$ROOT_DIR/selfhost/update_seed.sh"

echo "no-rust CI checks passed"
