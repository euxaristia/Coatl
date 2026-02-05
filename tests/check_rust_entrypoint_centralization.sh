#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Enforce that compile entrypoints use ./mee instead of ad-hoc cargo invocations.
# Keep compiler internals and ./mee itself out of scope for this check.
BAD=$(rg -n "cargo run --quiet -- build" \
  --glob '!compiler/**' \
  --glob '!mee' \
  --glob '!tests/check_rust_entrypoint_centralization.sh' \
  --glob '!*target/**' \
  . || true)

if [[ -n "$BAD" ]]; then
  echo "[FAIL] found direct cargo compile invocations outside centralized driver:"
  printf '%s\n' "$BAD"
  exit 1
fi

echo "rust entrypoint centralization check passed"
