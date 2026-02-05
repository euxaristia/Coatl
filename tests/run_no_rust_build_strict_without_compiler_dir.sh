#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER_DIR="$ROOT_DIR/compiler"
STASH_DIR="$ROOT_DIR/compiler.__disabled_for_no_rust_strict__"

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
  echo "compiler directory already absent; running strict gate directly"
fi

MEE_NO_RUST_BUILD=1 "$ROOT_DIR/tests/run_strict_no_rust_suite.sh"

echo "no-rust-build strict suite passed without compiler directory"
