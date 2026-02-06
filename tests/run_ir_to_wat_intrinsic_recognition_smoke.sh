#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-intrinsic-recog.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[intrinsic-recognition] validate WASI intrinsic and TTY stub lowering"

# IR that exercises __path_open and all three TTY intrinsics
IR="$TMP_DIR/intrinsics.ir"
WAT="$TMP_DIR/intrinsics.wat"

cat > "$IR" <<'IREOF'
(coatl_ir v0
  (structs)
  (functions
    (fn main
      (params)
      (ret i32)
      (block
        (let mode i32
          (int 512)
        )
        (let fd_out i32
          (int 0)
        )
        (let rc_open i32
          (call __path_open
          (int 3)
          (int 0)
          (int 1024)
          (int 5)
          (int 0)
          (int 1)
          (int 0)
          (int 0)
          (ident fd_out)
          )
        )
        (let rc_get i32
          (call __tty_get_mode
          (int 0)
          (ident mode)
          )
        )
        (let rc_raw i32
          (call __tty_set_raw
          (int 0)
          (ident mode)
          (int 0)
          (int 0)
          )
        )
        (let rc_restore i32
          (call __tty_restore
          (int 0)
          (ident mode)
          )
        )
        (return
          (int 0)
        )
      )
    )
  )
)
IREOF

"$ROOT_DIR/coatl" lower-ir "$IR" -o "$WAT"

fail() {
  echo "[FAIL] $1" >&2
  cat "$WAT" >&2
  exit 1
}

# __path_open must be recognized as WASI import, NOT emitted as call $__path_open
grep -Fq '(import "wasi_snapshot_preview1" "path_open"' "$WAT" \
  || fail "__path_open not recognized as WASI import (literal offset bug?)"

if grep -Fq 'call $__path_open' "$WAT"; then
  fail "__path_open emitted as user function call instead of WASI import call"
fi

# TTY intrinsics must be lowered to stubs (i32.const 58), NOT emitted as function calls
for fn in __tty_get_mode __tty_set_raw __tty_restore; do
  if grep -Fq "call \$$fn" "$WAT"; then
    fail "$fn emitted as user function call instead of stub (literal offset bug?)"
  fi
done

# The stubs should produce i32.const 58 (ENOTSUP)
grep -Fq 'i32.const 58' "$WAT" \
  || fail "TTY stubs missing i32.const 58 (ENOTSUP) return"

echo "  ok"
echo "ir_to_wat intrinsic recognition smoke passed"
