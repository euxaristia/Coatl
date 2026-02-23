#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COATL_BIN="${COATL_BIN:-$(command -v coatl || true)}"

if [[ -z "$COATL_BIN" && -x "$ROOT_DIR/coatl" ]]; then
  COATL_BIN="$ROOT_DIR/coatl"
fi
MODULE="/tmp/coatl-ir-to-cbyte.wat"

usage() {
  cat <<'EOF' >&2
usage:
  tools/ir_to_cbyte.sh <input.ir> -o <output.cbyte>
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

input="$1"
output=""
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$COATL_BIN" || ! -x "$COATL_BIN" ]]; then
  echo "ir_to_cbyte: coatl binary not found" >&2
  exit 1
fi

if [[ ! -f "$MODULE" ]]; then
  "$COATL_BIN" build "$ROOT_DIR/tools/ir_to_cbyte.coatl" --toolchain=selfhost -o "$MODULE" >/dev/null
fi

# Create a temporary directory to avoid polluting the workspace
TMP_EMIT_DIR="$(mktemp -d /tmp/coatl-cbyte-emit.XXXXXX)"
trap 'rm -rf "$TMP_EMIT_DIR"' EXIT

# The .coatl tool writes to "output.cbyte" in the current (preopen) dir
wasmtime --dir "$TMP_EMIT_DIR" --invoke main "$MODULE" > /dev/null

if [[ -f "$TMP_EMIT_DIR/output.cbyte" ]]; then
  cp "$TMP_EMIT_DIR/output.cbyte" "$output"
else
  echo "ir_to_cbyte: emitter failed to produce output.cbyte" >&2
  exit 1
fi
