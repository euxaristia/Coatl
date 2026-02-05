#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER_DIR="$ROOT_DIR/compiler"
STASH_DIR="$ROOT_DIR/compiler.__disabled_for_no_rust_check__"

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

if [[ -d "$COMPILER_DIR" ]]; then
  mv "$COMPILER_DIR" "$STASH_DIR"
else
  echo "compiler directory already absent; running no-rust-build checks directly"
fi

COATL_IR_FIRST_BUILD=1 "$ROOT_DIR/tests/run_no_rust_build_mode_full_coverage.sh"
COATL_IR_FIRST_BUILD=1 "$ROOT_DIR/tests/run_no_rust_build_mode_prefers_ir.sh"

echo "no-rust-build works without compiler directory"
