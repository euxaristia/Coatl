#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-hello-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[hello-world] compile hello.coatl to WAT via IR pipeline"
HELLO_WAT="$TMP_DIR/hello.wat"
"$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --toolchain=ir -o "$HELLO_WAT"

if [[ ! -s "$HELLO_WAT" ]]; then
  echo "[FAIL] hello.wat not created or empty"
  exit 1
fi
if ! head -n 1 "$HELLO_WAT" | grep -q "^(module"; then
  echo "[FAIL] hello.wat is not a WAT module"
  exit 1
fi

echo "[hello-world] run hello.wat with wasmtime"
out="$(wasmtime run "$HELLO_WAT" 2>&1)"
if ! printf '%s\n' "$out" | grep -Fq "Hello, world!"; then
  echo "[FAIL] expected 'Hello, world!' in output, got:"
  printf '%s\n' "$out"
  exit 1
fi

echo "[hello-world] compile hello.coatl to stdout (no -o)"
stdout_out="$("$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --toolchain=ir 2>/dev/null)"
if ! printf '%s\n' "$stdout_out" | head -n 1 | grep -q "^(module"; then
  echo "[FAIL] stdout output is not a WAT module"
  exit 1
fi

echo "hello-world smoke test passed"
