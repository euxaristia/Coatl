#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-ir-subset-pathopen.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

WAT="$TMP_DIR/path_open_probe.wat"
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/ir_subset_path_open_probe.coatl" --toolchain=ir -o "$WAT"

out="$(wasmtime --dir "$TMP_DIR" --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if ! [[ "$ret" =~ ^-?[0-9]+$ ]]; then
  echo "[FAIL] expected numeric return from path_open probe, got: $ret"
  printf '%s\n' "$out"
  exit 1
fi

echo "ir subset path_open smoke suite passed (rc=$ret)"
