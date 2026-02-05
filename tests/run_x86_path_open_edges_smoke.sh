#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-x86-path-open-edges.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "x86 path_open edge smoke currently supports Linux only"
  exit 1
fi

run_case() {
  local src="$1"
  local expected="$2"
  local bin="$TMP_DIR/$(basename "$src" .coatl).bin"
  COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" --emit=bin --toolchain=ir -o "$bin"
  set +e
  "$bin" >/dev/null 2>&1
  local rc=$?
  set -e
  if [[ "$rc" -ne "$expected" ]]; then
    echo "[FAIL] $src expected rc=$expected got rc=$rc"
    exit 1
  fi
  echo "  ok ($src rc=$expected)"
}

echo "[x86-path-open-edges] negative length"
run_case "tests/x86_path_open_len_negative_test.coatl" "22"

echo "[x86-path-open-edges] too-large length"
run_case "tests/x86_path_open_len_too_large_test.coatl" "22"

echo "x86 path_open edge smoke passed"
