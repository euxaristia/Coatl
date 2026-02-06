#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY_SCRIPT="$ROOT_DIR/tools/coatl_subset_to_ir.py"
ORIG_ARGS=("$@")
COATL_PYTHON="${COATL_PYTHON:-}"
COATL_BIN="${COATL_BIN:-$(command -v coatl || true)}"

if [[ -z "$COATL_BIN" && -x "$ROOT_DIR/coatl" ]]; then
  COATL_BIN="$ROOT_DIR/coatl"
fi
MODULE="/tmp/coatl-subset-to-ir.wat"

usage() {
  cat <<'EOF' >&2
usage:
  tools/coatl_subset_to_ir.sh <input.coatl> -o <output.ir>
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

input=""
output=""
input="$1"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      if [[ $# -lt 2 ]]; then
        echo "missing value for -o" >&2
        usage
        exit 1
      fi
      output="$2"
      shift 2
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$output" ]]; then
  echo "missing -o <output.ir>" >&2
  usage
  exit 1
fi

build_module() {
  "$COATL_BIN" build "$ROOT_DIR/tools/coatl_subset_to_ir.coatl" --emit=wat --toolchain=selfhost -o "$MODULE" >/dev/null
}

try_coatl_frontend() {
  if [[ -z "$COATL_BIN" || ! -x "$COATL_BIN" ]]; then
    return 1
  fi
  if ! command -v wasmtime >/dev/null 2>&1; then
    return 1
  fi
  if [[ ! -f "$MODULE" ]]; then
    build_module
  fi
  printf '%s -o %s\n' "$input" "$output" | wasmtime --invoke main "$MODULE"
}

find_python_cmd() {
  if [[ -n "$COATL_PYTHON" ]]; then
    if command -v "$COATL_PYTHON" >/dev/null 2>&1; then
      printf '%s' "$COATL_PYTHON"
      return 0
    fi
  fi
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

try_python_frontend() {
  if [[ ! -f "$PY_SCRIPT" ]]; then
    return 1
  fi
  local python_cmd
  if ! python_cmd="$(find_python_cmd)"; then
    echo "python3/python interpreter not found for fallback frontend" >&2
    return 1
  fi
  exec "$python_cmd" "$PY_SCRIPT" "${ORIG_ARGS[@]}"
}

if try_coatl_frontend; then
  exit 0
fi

if try_python_frontend; then
  exit 0
fi

echo "subset frontend failed" >&2
exit 1
