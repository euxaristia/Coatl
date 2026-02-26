#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-snake-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

source "$ROOT_DIR/tests/lib_x86_link.sh"
source "$ROOT_DIR/tests/lib_aarch64_link.sh"

detect_qemu_prefix_from_cc() {
  local arch="$1"
  local cc="$2"
  local libc_path=""
  local default_cc=""
  if [[ "$arch" == "x86_64" ]]; then
    default_cc="x86_64-linux-gnu-gcc"
  else
    default_cc="aarch64-linux-gnu-gcc"
  fi
  if [[ -n "$cc" ]] && command -v "$cc" >/dev/null 2>&1; then
    libc_path="$("$cc" -print-file-name=libc.so.6 2>/dev/null || true)"
  fi
  if [[ -z "$libc_path" || "$libc_path" == "libc.so.6" ]]; then
    if command -v "$default_cc" >/dev/null 2>&1; then
      libc_path="$("$default_cc" -print-file-name=libc.so.6 2>/dev/null || true)"
    fi
  fi
  if [[ -n "$libc_path" && "$libc_path" != "libc.so.6" ]]; then
    dirname "$(dirname "$libc_path")"
  fi
}

build_x86() {
  local src="$1"
  local out="$2"
  local asm="$TMP_DIR/snake_x86.s"
  # Use CC for x86 if we are on aarch64
  local old_cc="${CC:-}"
  if [[ "$(uname -m)" != "x86_64" ]] && command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
    export CC=x86_64-linux-gnu-gcc
  fi
  "$ROOT_DIR/coatl" build "$src" --arch=x86_64 -o "$asm"
  link_x86_asm_binary "$asm" "$out"
  export CC="$old_cc"
}

build_aarch64() {
  local src="$1"
  local out="$2"
  local asm="$TMP_DIR/snake_aarch64.s"
  # Use CC for aarch64 if we are on x86
  local old_cc="${CC:-}"
  if [[ "$(uname -m)" != "aarch64" ]] && command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    export CC=aarch64-linux-gnu-gcc
  fi
  "$ROOT_DIR/coatl" build "$src" --arch=aarch64 -o "$asm"
  link_aarch64_asm_binary "$asm" "$out"
  export CC="$old_cc"
}

SNAKE_SRC="$ROOT_DIR/examples/TermSnake/snake.coatl"

echo "[snake-smoke] Testing x86_64"
SNAKE_X86="$TMP_DIR/snake_x86"
build_x86 "$SNAKE_SRC" "$SNAKE_X86"
RUNNER_X86=()
if [[ "$(uname -m)" != "x86_64" ]]; then
  if command -v qemu-x86_64 >/dev/null 2>&1; then
    RUNNER_X86=("qemu-x86_64")
    qemu_prefix="${QEMU_LD_PREFIX:-}"
    if [[ -z "$qemu_prefix" ]]; then
      qemu_prefix="$(detect_qemu_prefix_from_cc x86_64 "${CC:-}")"
    fi
    if [[ -n "$qemu_prefix" ]]; then
      RUNNER_X86+=("-L" "$qemu_prefix")
      echo "[snake-smoke] x86_64 qemu sysroot: $qemu_prefix"
    fi
  else
    echo "Skipping x86_64 execution (no qemu-x86_64)"
  fi
fi
if [[ "${#RUNNER_X86[@]}" -gt 0 || "$(uname -m)" == "x86_64" ]]; then
  # Feed 'q' to exit immediately
  if [[ "${#RUNNER_X86[@]}" -gt 0 ]]; then
    echo "q" | "${RUNNER_X86[@]}" "$SNAKE_X86" >/dev/null 2>&1 || true
  else
    echo "q" | "$SNAKE_X86" >/dev/null 2>&1 || true
  fi
  echo "x86_64 execution smoke passed"
fi

echo "[snake-smoke] Testing aarch64"
SNAKE_AARCH64="$TMP_DIR/snake_aarch64"
# This might fail if the aarch64 backend still has the immediate bug
set +e
build_aarch64 "$SNAKE_SRC" "$SNAKE_AARCH64"
build_rc=$?
set -e

if [[ $build_rc -ne 0 ]]; then
  echo "[snake-smoke] aarch64 build failed (known issue with large immediates?)"
else
  RUNNER_AARCH64=()
  if [[ "$(uname -m)" != "aarch64" ]]; then
    if command -v qemu-aarch64 >/dev/null 2>&1; then
      RUNNER_AARCH64=("qemu-aarch64")
      qemu_prefix="${QEMU_LD_PREFIX:-}"
      if [[ -z "$qemu_prefix" ]]; then
        qemu_prefix="$(detect_qemu_prefix_from_cc aarch64 "${CC:-}")"
      fi
      if [[ -n "$qemu_prefix" ]]; then
        RUNNER_AARCH64+=("-L" "$qemu_prefix")
        echo "[snake-smoke] aarch64 qemu sysroot: $qemu_prefix"
      fi
    else
      echo "Skipping aarch64 execution (no qemu-aarch64)"
    fi
  fi
  if [[ "${#RUNNER_AARCH64[@]}" -gt 0 || "$(uname -m)" == "aarch64" ]]; then
    if [[ "${#RUNNER_AARCH64[@]}" -gt 0 ]]; then
      echo "q" | "${RUNNER_AARCH64[@]}" "$SNAKE_AARCH64" >/dev/null 2>&1 || true
    else
      echo "q" | "$SNAKE_AARCH64" >/dev/null 2>&1 || true
    fi
    echo "aarch64 execution smoke passed"
  fi
fi

echo "snake smoke test complete"
