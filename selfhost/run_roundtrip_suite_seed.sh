#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEED_CHECK="$ROOT_DIR/selfhost/check_self_compile_seed.sh"
BUILD_SELFHOST="$ROOT_DIR/selfhost/build_with_selfhost.sh"
TMP_DIR="$(mktemp -d /tmp/mee-seed-roundtrip.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

compile_with_selfhost() {
  local src="$1"
  local out_wat="$2"
  "$BUILD_SELFHOST" build "$ROOT_DIR/$src" -o "$out_wat" >/dev/null
}

check_case() {
  local src="$1"
  local expected_ret="$2"
  local expect_substr="${3:-}"
  local base
  base=$(basename "$src" .mee)
  local wat="$TMP_DIR/${base}.wat"

  echo "[case] $src"
  compile_with_selfhost "$src" "$wat"

  local out
  out=$(wasmtime --invoke main "$wat")
  local ret
  ret=$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')

  if [[ "$ret" != "$expected_ret" ]]; then
    echo "selfhost return mismatch for $src: got $ret expected $expected_ret"
    printf '%s\n' "$out"
    exit 1
  fi

  if [[ -n "$expect_substr" ]]; then
    if ! printf '%s\n' "$out" | grep -Fq "$expect_substr"; then
      echo "selfhost output missing expected text for $src: $expect_substr"
      printf '%s\n' "$out"
      exit 1
    fi
  fi

  echo "  ok (return=$expected_ret)"
}

echo "[seed-roundtrip] Verifying self-compile convergence (no Rust)"
"$SEED_CHECK"

echo "[seed-roundtrip] Running runtime suite (no Rust)"
check_case "tests/mem_test.mee" "142"
check_case "tests/array_sim.mee" "100"
check_case "tests/byte_test.mee" "389"
check_case "examples/hello.mee" "0" "Hello, world!"

echo "All seed-only round-trip checks passed"
