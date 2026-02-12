#!/usr/bin/env bash
set -euo pipefail

cc_bin() {
  echo "${CC:-cc}"
}

have_cc_toolchain() {
  local cc
  cc="$(cc_bin)"
  command -v "$cc" >/dev/null 2>&1 && "$cc" --version >/dev/null 2>&1
}

have_as_toolchain() {
  command -v as >/dev/null 2>&1 && as --version >/dev/null 2>&1
}

have_internal_linker() {
  [[ -f "$ROOT_DIR/tools/link_aarch64_elf.sh" ]]
}

have_aarch64_link_toolchain() {
  have_cc_toolchain || (have_as_toolchain && (have_internal_linker || (command -v ld >/dev/null 2>&1 && ld --version >/dev/null 2>&1)))
}

link_aarch64_asm_binary() {
  local asm="$1"
  local bin="$2"
  if have_cc_toolchain; then
    local cc
    cc="$(cc_bin)"
    "$cc" -no-pie "$asm" -o "$bin"
    return 0
  fi
  if have_as_toolchain; then
    local obj
    obj="$(mktemp /tmp/coatl-aarch64-link.XXXXXX.o)"
    as "$asm" -o "$obj"
    if have_internal_linker; then
      bash "$ROOT_DIR/tools/link_aarch64_elf.sh" "$obj" -o "$bin" --entry coatl_start
    else
      ld "$obj" -o "$bin" -e coatl_start
    fi
    rm -f "$obj"
    return 0
  fi
  echo "aarch64 link toolchain unavailable (need usable CC or as+ld)" >&2
  return 1
}
