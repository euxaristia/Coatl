#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-auto-wat-full-norust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MISSING_SEED="/tmp/mee-missing-seed.wat"
failed=0
while IFS= read -r src; do
  out="$TMP_DIR/$(basename "$src" .mee).wat"
  if ! MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/$src" --emit=wat --toolchain=auto --compiler "$MISSING_SEED" -o "$out" >/dev/null 2>"$TMP_DIR/err.log"; then
    failed=1
    echo "[FAIL] $src"
    sed -n '1,4p' "$TMP_DIR/err.log"
  fi
done < <(cd "$ROOT_DIR" && rg --files tests examples selfhost | rg '\.mee$')

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "no-rust full auto wat compile coverage passed"
