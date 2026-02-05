#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER_DIR="$ROOT_DIR/compiler"
STASH_DIR="$ROOT_DIR/compiler.__disabled_for_no_rust_check__"

if [[ ! -d "$COMPILER_DIR" ]]; then
  echo "compiler directory not found: $COMPILER_DIR"
  exit 1
fi
if [[ -e "$STASH_DIR" ]]; then
  echo "stash path already exists: $STASH_DIR"
  exit 1
fi

restore() {
  if [[ -d "$STASH_DIR" && ! -e "$COMPILER_DIR" ]]; then
    mv "$STASH_DIR" "$COMPILER_DIR"
  fi
}
trap restore EXIT

mv "$COMPILER_DIR" "$STASH_DIR"

MEE_NO_RUST_BUILD=1 "$ROOT_DIR/tests/run_no_rust_build_mode_full_coverage.sh"
MEE_NO_RUST_BUILD=1 "$ROOT_DIR/tests/run_no_rust_build_mode_prefers_ir.sh"

echo "no-rust-build works without compiler directory"
