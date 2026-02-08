#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-wat-structure.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[wat-structure] validate WAT output structure for hello.coatl"

IR="$TMP_DIR/hello.ir"
WAT="$TMP_DIR/hello.wat"

"$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --toolchain=ir -o "$IR"
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

fail() {
  echo "[FAIL] $1" >&2
  echo "WAT contents:" >&2
  head -20 "$WAT" >&2
  exit 1
}

head -1 "$WAT" | grep -Fq "(module" || fail "WAT does not start with (module"
grep -Fq '(export "main"' "$WAT" || fail "missing main export"
grep -Fq '(func $_start' "$WAT" || fail "missing _start wrapper"
grep -Fq '(import "wasi_snapshot_preview1" "fd_write"' "$WAT" || fail "missing fd_write import"

echo "  ok"
echo "ir_to_wat WAT structure smoke passed"
