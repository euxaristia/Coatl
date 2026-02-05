#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEED_WAT_DEFAULT="$ROOT_DIR/selfhost/bootstrap.seed.wat"
source "$ROOT_DIR/selfhost/wat_utils.sh"

usage() {
  cat <<'EOF'
usage:
  ./selfhost/build_with_selfhost.sh build <input.coatl> -o <output.wat> [--compiler <seed.wat>]

notes:
  - Requires wasmtime.
  - Uses a prebuilt self-hosted seed compiler WAT (default: selfhost/bootstrap.seed.wat).
  - Does not invoke external compiler lanes.
EOF
}

if [[ $# -lt 4 ]]; then
  usage
  exit 1
fi

cmd="$1"
if [[ "$cmd" != "build" ]]; then
  usage
  exit 1
fi

in_file="$2"
shift 2

out_file=""
compiler_wat="$SEED_WAT_DEFAULT"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out_file="${2:-}"
      shift 2
      ;;
    --compiler)
      compiler_wat="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown arg: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$out_file" ]]; then
  echo "missing -o <output.wat>"
  exit 1
fi
if [[ ! -f "$in_file" ]]; then
  echo "input file not found: $in_file"
  exit 1
fi
if [[ "$in_file" != *.coatl ]]; then
  echo "input file must use .coatl extension: $in_file"
  exit 1
fi
if [[ ! -f "$compiler_wat" ]]; then
  echo "compiler seed not found: $compiler_wat"
  exit 1
fi
if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

tmpdir="$(mktemp -d /tmp/coatl-selfhost-build.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT
patched="$tmpdir/compiler.stdin.wat"
raw="$tmpdir/out.raw"

patch_stdin_flag "$compiler_wat" "$patched"
wasmtime --invoke main "$patched" < "$in_file" > "$raw"
clean_wat_output "$raw" "$out_file"

prefix="$(head -c 7 "$out_file")"
if [[ "$prefix" != "(module" ]]; then
  echo "self-host compile failed: output is not WAT module" >&2
  head -c 200 "$out_file" >&2
  exit 1
fi

echo "wrote $out_file"
