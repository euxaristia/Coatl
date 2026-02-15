#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
usage:
  tools/link_aarch64_elf.sh <input.o> -o <output.bin> [--entry <symbol>]

notes:
  - Runs the Coatl linker implementation in tools/link_aarch64_elf.coatl.
  - Requires a prebuilt linker binary or a usable C toolchain to build it.
USAGE
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

input=""
output=""
entry="coatl_start"

input="$1"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      output="${2:-}"
      shift 2
      ;;
    --entry)
      entry="${2:-}"
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
  echo "missing -o <output.bin>" >&2
  exit 1
fi
if [[ ! -f "$input" ]]; then
  echo "input file not found: $input" >&2
  exit 1
fi

bin="/tmp/coatl-link-aarch64_elf.bin"
if [[ ! -x "$bin" ]]; then
  asm="/tmp/coatl-link-aarch64_elf.s"
  obj="/tmp/coatl-link-aarch64_elf.o"
  "$ROOT_DIR/coatl" build "$ROOT_DIR/tools/link_aarch64_elf.coatl" --toolchain=ir --arch=aarch64 -o "$asm" >/dev/null
  # Fix large immediates that exceed 16 bits in aarch64
  sed -i 's/mov w0, #135168/mov w0, #0x2100\n  movk w0, #0x2, lsl #16/' "$asm"
  sed -i 's/mov w0, #139264/mov w0, #0x2200\n  movk w0, #0x2, lsl #16/' "$asm"
  sed -i 's/mov w0, #262144/mov w0, #0\n  movk w0, #0x4, lsl #16/' "$asm"
  sed -i 's/mov w0, #401408/mov w0, #0x200\n  movk w0, #0x6, lsl #16/' "$asm"
  if command -v cc >/dev/null 2>&1; then
    cc -fPIE -pie -Wl,-z,relro,-z,now -Wl,-z,noexecstack "$asm" -o "$bin"
  elif command -v ld >/dev/null 2>&1 && command -v as >/dev/null 2>&1; then
    as "$asm" -o "$obj"
    ld "$obj" -o "$bin" -e main
  else
    echo "linker build requires cc or as+ld" >&2
    exit 1
  fi
fi

echo "$input" "$output" "$entry" | "$bin"
