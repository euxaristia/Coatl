#!/usr/bin/env bash
set -euo pipefail

patch_stdin_flag() {
  local in_wat="$1"
  local out_wat="$2"
  local flag=18874412 # state_base + 44
  local needle="(data (i32.const ${flag}) \"\\\\01\")"

  if grep -Fq "$needle" "$in_wat"; then
    cp "$in_wat" "$out_wat"
    return 0
  fi

  awk -v needle="$needle" '
    !done && $0 ~ /\(memory/ {
      print "  " needle
      done=1
    }
    { print }
  ' "$in_wat" > "$out_wat"
}

clean_wat_output() {
  local in_raw="$1"
  local out_wat="$2"
  LC_ALL=C awk 'BEGIN{RS="\0"} NR==1{
    sub(/[ \t\r\n]+$/, "", $0)
    print $0
    exit
  }' "$in_raw" > "$out_wat"
}
