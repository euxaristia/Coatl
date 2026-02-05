#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-cli-no-rust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[cli-no-rust] build hello with selfhost toolchain"
HELLO_WAT="$TMP_DIR/hello.wat"
"$ROOT_DIR/mee" build "$ROOT_DIR/examples/hello.mee" --emit=wat --toolchain=selfhost -o "$HELLO_WAT"

if [[ ! -s "$HELLO_WAT" ]]; then
  echo "[FAIL] hello.wat not created"
  exit 1
fi
if ! head -n 1 "$HELLO_WAT" | grep -q "^(module"; then
  echo "[FAIL] hello.wat is not a WAT module"
  exit 1
fi

out="$(wasmtime --invoke main "$HELLO_WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "0" ]]; then
  echo "[FAIL] expected return 0, got $ret"
  printf '%s\n' "$out"
  exit 1
fi
if ! printf '%s\n' "$out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] missing expected output text"
  printf '%s\n' "$out"
  exit 1
fi

echo "cli no-rust smoke suite passed"
