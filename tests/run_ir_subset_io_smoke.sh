#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-subset-io.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

WAT="$TMP_DIR/fdread.wat"
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/x86_fd_read_test.coatl" --emit=wat --toolchain=ir -o "$WAT"

set +e
out="$(printf "abcd" | wasmtime --invoke main "$WAT")"
rc=$?
set -e
if [[ "$rc" -ne 0 ]]; then
  echo "[FAIL] wasmtime execution failed rc=$rc"
  printf '%s\n' "$out"
  exit 1
fi
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "4" ]]; then
  echo "[FAIL] expected ret=4 got ret=$ret"
  printf '%s\n' "$out"
  exit 1
fi

echo "ir subset io smoke suite passed"
