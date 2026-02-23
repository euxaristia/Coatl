#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COATL_BIN="${COATL_BIN:-$(command -v coatl || true)}"

if [[ -z "$COATL_BIN" && -x "$ROOT_DIR/coatl" ]]; then
  COATL_BIN="$ROOT_DIR/coatl"
fi
MODULE="/tmp/coatl-cbyte-vm.wat"

usage() {
  cat <<'EOF' >&2
usage:
  tools/cbyte_vm.sh <input.cbyte>
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

input="$1"

if [[ -z "$COATL_BIN" || ! -x "$COATL_BIN" ]]; then
  echo "cbyte_vm: coatl binary not found" >&2
  exit 1
fi

if [[ ! -f "$MODULE" ]]; then
  "$COATL_BIN" build "$ROOT_DIR/tools/cbyte_vm.coatl" --toolchain=selfhost -o "$MODULE" >/dev/null
fi

abs_input="$(realpath "$input")"
input_dir="$(dirname "$abs_input")"
rel_input="$(basename "$abs_input")"

# Create a temporary directory to avoid polluting the workspace
TMP_RUN_DIR="$(mktemp -d /tmp/coatl-vm-run.XXXXXX)"
trap 'rm -rf "$TMP_RUN_DIR"' EXIT

cp "$abs_input" "$TMP_RUN_DIR/input.cbyte"
ls -la "$TMP_RUN_DIR" >&2

wasmtime --dir "$TMP_RUN_DIR" --invoke main "$MODULE"
