#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-full-asm-norust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "no-rust full ir asm compile coverage currently supports Linux only"
  exit 1
fi

failed=0
while IFS= read -r src; do
  out="$TMP_DIR/$(basename "$src" .coatl).s"
  if ! COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --toolchain=ir -o "$out" >/dev/null 2>"$TMP_DIR/err.log"; then
    failed=1
    echo "[FAIL] $src"
    sed -n '1,4p' "$TMP_DIR/err.log"
  fi
done < <(cd "$ROOT_DIR" && rg --files tests examples selfhost | rg '\.coatl$')

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "no-rust full ir asm compile coverage passed"
