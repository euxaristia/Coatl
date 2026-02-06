#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
usage:
  tools/link_x86_64_elf.sh <input.o> -o <output.bin> [--entry <symbol>]

notes:
  - Runs the Coatl linker implementation in tools/link_x86_64_elf.coatl.
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

bin="/tmp/coatl-link-x86_64_elf.bin"
if [[ ! -x "$bin" ]]; then
  asm="/tmp/coatl-link-x86_64_elf.s"
  obj="/tmp/coatl-link-x86_64_elf.o"
  "$ROOT_DIR/coatl" build "$ROOT_DIR/tools/link_x86_64_elf.coatl" --emit=asm --toolchain=ir -o "$asm" >/dev/null
  if command -v cc >/dev/null 2>&1; then
    cc -no-pie "$asm" -o "$bin"
  elif command -v ld >/dev/null 2>&1 && command -v as >/dev/null 2>&1; then
    as --64 "$asm" -o "$obj"
    ld "$obj" -o "$bin" -e coatl_start
  else
    echo "linker build requires cc or as+ld" >&2
    exit 1
  fi
fi

echo "$input" "$output" "$entry" | "$bin"
