#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-tty-intrinsics.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

echo "[tty-intrinsics] compile IR"
IR="$TMP_DIR/tty.ir"
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/tty_intrinsics_wasi_test.coatl" --emit=ir --toolchain=ir -o "$IR"
grep -Fq "(call __tty_get_mode" "$IR"
grep -Fq "(call __tty_set_raw" "$IR"
grep -Fq "(call __tty_restore" "$IR"

echo "[tty-intrinsics] compile WAT and validate graceful unsupported return"
WAT="$TMP_DIR/tty.wat"
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/tty_intrinsics_wasi_test.coatl" --emit=wat --toolchain=ir -o "$WAT"
out="$(wasmtime --invoke main "$WAT")"
ret="$(printf '%s\n' "$out" | awk 'NF { line=$0 } END { print line }')"
if [[ "$ret" != "58" ]]; then
  echo "[FAIL] expected WASI unsupported return 58, got $ret"
  printf '%s\n' "$out"
  exit 1
fi

echo "[tty-intrinsics] compile ASM and verify intrinsic runtime shims are present"
ASM="$TMP_DIR/tty.s"
"$ROOT_DIR/coatl" build "$ROOT_DIR/tests/tty_intrinsics_wasi_test.coatl" --emit=asm --toolchain=ir -o "$ASM"
grep -Fq "__tty_get_mode:" "$ASM"
grep -Fq "__tty_set_raw:" "$ASM"
grep -Fq "__tty_restore:" "$ASM"

echo "tty intrinsic smoke suite passed"
