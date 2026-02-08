#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-subset-frontend.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[ir-subset-frontend] emit IR via toolchain=ir"
IR="$TMP_DIR/hello-subset.ir"
"$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --toolchain=ir -o "$IR"

if [[ ! -s "$IR" ]]; then
  echo "[FAIL] no IR output"
  exit 1
fi

grep -Eq "^\(coatl_ir v[0-9]" "$IR"
grep -Fq "(fn main" "$IR"
grep -Fq "(call __fd_write" "$IR"

echo "ir subset frontend smoke suite passed"
