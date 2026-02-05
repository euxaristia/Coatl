#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER_DIR="$ROOT_DIR/compiler"
STASH_DIR="$ROOT_DIR/compiler.__missing_rust_lane_smoke__"
TMP_DIR="$(mktemp -d /tmp/mee-missing-compiler-rust-lane.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -e "$STASH_DIR" ]]; then
  echo "stash path already exists: $STASH_DIR"
  exit 1
fi
if [[ ! -d "$COMPILER_DIR" ]]; then
  echo "compiler directory not found: $COMPILER_DIR"
  exit 1
fi

restore() {
  if [[ -d "$STASH_DIR" && ! -e "$COMPILER_DIR" ]]; then
    mv "$STASH_DIR" "$COMPILER_DIR"
  fi
}
trap restore EXIT

mv "$COMPILER_DIR" "$STASH_DIR"

set +e
"$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=wat --toolchain=rust -o "$TMP_DIR/hello.wat" >"$TMP_DIR/out.log" 2>"$TMP_DIR/err.log"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "[FAIL] expected rust toolchain build to fail with compiler directory missing"
  exit 1
fi
if ! grep -Fq "rust compiler lane unavailable" "$TMP_DIR/err.log"; then
  echo "[FAIL] missing expected unavailable-rust-lane error"
  cat "$TMP_DIR/err.log"
  exit 1
fi

echo "missing compiler rust-lane smoke passed"
