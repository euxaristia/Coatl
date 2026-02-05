#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-subset-writeclose.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

WAT="$TMP_DIR/path_open_write_close.wat"
OUTFILE="$TMP_DIR/probe_out.txt"

"$ROOT_DIR/mee" build "$ROOT_DIR/tests/ir_subset_path_open_write_close.mee" --emit=wat --toolchain=ir -o "$WAT"

out="$(wasmtime --dir "$TMP_DIR" --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "3" ]]; then
  echo "[FAIL] expected ret=3 got ret=$ret"
  printf '%s\n' "$out"
  exit 1
fi

if [[ ! -f "$OUTFILE" ]]; then
  echo "[FAIL] output file missing: $OUTFILE"
  exit 1
fi
if ! printf "OK\n" | cmp -s - "$OUTFILE"; then
  echo "[FAIL] file contents mismatch"
  echo "got:"
  cat "$OUTFILE"
  exit 1
fi

echo "ir subset path_open+write+close smoke suite passed"
