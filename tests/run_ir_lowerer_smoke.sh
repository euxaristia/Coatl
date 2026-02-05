#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-ir-lowerer.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

IR="$TMP_DIR/simple.ir"
WAT="$TMP_DIR/simple.wat"

cat > "$IR" <<'IR'
(mee_ir v0
  (structs)
  (functions
    (fn main
      (params)
      (ret i32)
      (block
        (let a i32
          (int 40)
        )
        (return
          (binary add
            (ident a)
            (int 2)
          )
        )
      )
    )
  )
)
IR

echo "[ir-lowerer] lower IR -> WAT via non-Rust backend lane"
"$ROOT_DIR/mee" lower-ir "$IR" -o "$WAT"

if [[ ! -s "$WAT" ]]; then
  echo "[FAIL] lower-ir did not produce output"
  exit 1
fi
if ! head -n 1 "$WAT" | grep -q "^(module"; then
  echo "[FAIL] lowered output is not WAT"
  exit 1
fi

out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "42" ]]; then
  echo "[FAIL] expected return 42, got $ret"
  printf '%s\n' "$out"
  exit 1
fi

echo "ir lowerer smoke suite passed"
