#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-file-io-rt.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[file-io-roundtrip] validate ir_to_wat file I/O (WASI path_open oflags)"

IR="$TMP_DIR/hello.ir"
WAT_TOOL="$TMP_DIR/hello-tool.wat"
WAT_REF="$TMP_DIR/hello-ref.wat"

# Generate IR
"$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --toolchain=ir -o "$IR"

# Lower via the tool wrapper (exercises write_output with WASI oflags)
"$ROOT_DIR/tools/ir_to_wat.sh" "$IR" -o "$WAT_TOOL"

if [[ ! -s "$WAT_TOOL" ]]; then
  echo "[FAIL] tool produced empty WAT (write_output oflags bug?)" >&2
  exit 1
fi

head -1 "$WAT_TOOL" | grep -Fq "(module" || {
  echo "[FAIL] WAT does not start with (module" >&2
  head -5 "$WAT_TOOL" >&2
  exit 1
}

# Execute the WAT — should print "Hello, world!"
out="$(wasmtime "$WAT_TOOL" 2>&1)"
if [[ "$out" != *"Hello, world!"* ]]; then
  echo "[FAIL] expected 'Hello, world!' output, got: $out" >&2
  exit 1
fi

# Compare with reference from coatl lower-ir (same backend, different entry path)
"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT_REF"
if ! diff -q "$WAT_TOOL" "$WAT_REF" >/dev/null 2>&1; then
  echo "[FAIL] tool output differs from lower-ir reference" >&2
  diff "$WAT_TOOL" "$WAT_REF" >&2
  exit 1
fi

echo "  ok"
echo "ir_to_wat file I/O roundtrip smoke passed"
