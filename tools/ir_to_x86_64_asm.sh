#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COATL_IR_TO_X86_ASM="${COATL_IR_TO_X86_ASM:-}"
DEFAULT_BIN="$ROOT_DIR/tools/ir_to_x86_64_asm.bin"
PY_SCRIPT="$ROOT_DIR/tools/ir_to_x86_64_asm.py"

find_python_cmd() {
  if [[ -n "${COATL_PYTHON:-}" ]] && command -v "$COATL_PYTHON" >/dev/null 2>&1; then
    printf '%s' "$COATL_PYTHON"
    return 0
  fi
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

exec_candidate() {
  local candidate="$1"
  shift
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    exec "$candidate" "$@"
  fi
  return 1
}

if exec_candidate "$COATL_IR_TO_X86_ASM" "$@"; then
  :
elif exec_candidate "$DEFAULT_BIN" "$@"; then
  :
else
  if [[ -n "$COATL_IR_TO_X86_ASM" && ! -x "$COATL_IR_TO_X86_ASM" ]]; then
    echo "COATL_IR_TO_X86_ASM is set but not executable: $COATL_IR_TO_X86_ASM" >&2
  else
    if [[ -f "$PY_SCRIPT" ]]; then
      if python_cmd="$(find_python_cmd)"; then
        exec "$python_cmd" "$PY_SCRIPT" "$@"
      fi
      echo "python3/python interpreter not found for ir_to_x86_64_asm fallback" >&2
      exit 1
    fi
    echo "ir_to_x86_64_asm binary not found; build a Coatl-native tool and set COATL_IR_TO_X86_ASM or place tools/ir_to_x86_64_asm.bin" >&2
  fi
  exit 1
fi
