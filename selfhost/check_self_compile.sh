#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec "$ROOT_DIR/selfhost/check_self_compile_seed.sh"
