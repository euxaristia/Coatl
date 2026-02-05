#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEED_WAT_DEFAULT="$ROOT_DIR/selfhost/bootstrap.seed.wat"

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

python3 - "$compiler_wat" "$patched" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1]).read_text(errors='ignore')
flag = 18874412  # state_base + 44
needle = f'(data (i32.const {flag}) "\\01")'
if needle not in src:
    src = src.replace('(memory', f'  {needle}\n  (memory', 1)
Path(sys.argv[2]).write_text(src)
PY

wasmtime --invoke main "$patched" < "$in_file" > "$raw"

python3 - "$raw" "$out_file" <<'PY'
from pathlib import Path
import sys
raw = Path(sys.argv[1]).read_bytes()
if b'\x00' in raw:
    raw = raw.split(b'\x00', 1)[0]
raw = raw.rstrip(b'\r\n\t ') + b'\n'
text = raw.decode('utf-8', errors='ignore')
if not text.startswith('(module'):
    print("self-host compile failed: output is not WAT module", file=sys.stderr)
    print(text[:200], file=sys.stderr)
    sys.exit(1)
Path(sys.argv[2]).write_text(text)
PY

echo "wrote $out_file"
