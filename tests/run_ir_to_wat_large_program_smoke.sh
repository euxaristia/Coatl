#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-large-program.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[large-program] validate ir_to_wat handles bootstrap-scale IR (77K+ nodes, 638 functions)"

IR="$TMP_DIR/bootstrap.ir"
WAT="$TMP_DIR/bootstrap.wat"

# Generate IR for the selfhost bootstrap (largest program in the repo)
"$ROOT_DIR/coatl" build "$ROOT_DIR/selfhost/bootstrap.coatl" --emit=ir --toolchain=ir -o "$IR"

if [[ ! -s "$IR" ]]; then
  echo "[FAIL] IR generation produced empty file" >&2
  exit 1
fi

# Lower via the Coatl backend (exercises node limit, fn_names limit)
"$ROOT_DIR/tools/ir_to_wat.sh" "$IR" -o "$WAT"

if [[ ! -s "$WAT" ]]; then
  echo "[FAIL] WAT output is empty" >&2
  exit 1
fi

head -1 "$WAT" | grep -Fq "(module" || {
  echo "[FAIL] WAT does not start with (module" >&2
  head -5 "$WAT" >&2
  exit 1
}

# Bootstrap has 638 functions; verify a substantial number made it through
func_count="$(grep -c '(func \$' "$WAT")"
if [[ "$func_count" -lt 600 ]]; then
  echo "[FAIL] expected >600 functions, got $func_count (fn_names limit?)" >&2
  exit 1
fi

echo "  ok ($func_count functions)"
echo "ir_to_wat large program smoke passed"
