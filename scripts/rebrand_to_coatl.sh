#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="dry-run"
BACKUP_EXT=".bak"

usage() {
  cat <<'USAGE'
usage:
  ./scripts/rebrand_to_coatl.sh [--apply] [--no-backup]

notes:
  - default mode is dry-run (prints planned actions only)
  - apply mode edits files with in-place backups (*.bak) unless --no-backup is set
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      MODE="apply"
      shift
      ;;
    --no-backup)
      BACKUP_EXT=""
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

log() {
  printf '%s\n' "$*"
}

maybe_mv() {
  local src="$1"
  local dst="$2"
  if [[ "$MODE" == "dry-run" ]]; then
    log "[dry-run] mv '$src' '$dst'"
    return 0
  fi
  if [[ -e "$dst" ]]; then
    log "[skip] target exists: $dst"
    return 0
  fi
  mv "$src" "$dst"
  log "[ok] mv '$src' '$dst'"
}

is_text_file() {
  local f="$1"
  grep -Iq . "$f"
}

transform_file() {
  local f="$1"
  if [[ "$MODE" == "dry-run" ]]; then
    if rg -q "\bMee\b|\bmee\b|\bMEE_" "$f"; then
      log "[dry-run] edit '$f'"
    fi
    return 0
  fi

  if [[ -n "$BACKUP_EXT" ]]; then
    perl -i"$BACKUP_EXT" -pe 's/\bMee\b/Coatl/g; s/\bmee\b/coatl/g; s/\bMEE_/COATL_/g' "$f"
  else
    perl -i -pe 's/\bMee\b/Coatl/g; s/\bmee\b/coatl/g; s/\bMEE_/COATL_/g' "$f"
  fi

  # Motif language updates in docs/comments.
  if [[ -n "$BACKUP_EXT" ]]; then
    perl -i"$BACKUP_EXT" -pe "s/Coatl's simplicity/Coatl's fluidity/g; s/Coatl\x27s simplicity/Coatl\x27s fluidity/g" "$f"
  else
    perl -i -pe "s/Coatl's simplicity/Coatl's fluidity/g; s/Coatl\x27s simplicity/Coatl\x27s fluidity/g" "$f"
  fi
}

log "== Phase 1: file system migration =="

# 1) .coatl -> .coatl
while IFS= read -r path; do
  new_path="${path%.coatl}.coatl"
  maybe_mv "$path" "$new_path"
done < <(cd "$ROOT_DIR" && rg --files -g '*.coatl')

# 2) rename any directory named coatl -> coatl (deepest first)
while IFS= read -r d; do
  parent="$(dirname "$d")"
  maybe_mv "$d" "$parent/coatl"
done < <(find "$ROOT_DIR" -depth -type d -name 'coatl' | sort)

# 3) config file renames
while IFS= read -r cfg; do
  base="$(basename "$cfg")"
  dir="$(dirname "$cfg")"
  case "$base" in
    meefile|coatl.json)
      maybe_mv "$cfg" "$dir/Coatl.json"
      ;;
    build.coatl)
      maybe_mv "$cfg" "$dir/build.coatl"
      ;;
  esac
done < <(cd "$ROOT_DIR" && rg --files | rg '(^|/)(meefile|coatl\.json|build\.coatl)$')

# Rename top-level CLI/man entrypoints if present.
if [[ -f "$ROOT_DIR/coatl" ]]; then
  maybe_mv "$ROOT_DIR/coatl" "$ROOT_DIR/coatl"
fi
if [[ -f "$ROOT_DIR/man/coatl.1" ]]; then
  maybe_mv "$ROOT_DIR/man/coatl.1" "$ROOT_DIR/man/coatl.1"
fi

log "== Phase 2: source code analysis + replacement =="

while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  if is_text_file "$f"; then
    transform_file "$f"
  fi
done < <(find "$ROOT_DIR" -type f \
  -not -path "$ROOT_DIR/.git/*" \
  -not -path "$ROOT_DIR/.claude/*" \
  -not -name "*.bak" | sort)

log "== Phase 3: motif + metadata alignment =="

README="$ROOT_DIR/README.md"
if [[ -f "$README" && "$MODE" == "apply" ]]; then
  if [[ -n "$BACKUP_EXT" ]]; then
    cp "$README" "$README$BACKUP_EXT"
  fi
  # Ensure serpent motif headline exists.
  if ! rg -q 'Serpent|serpent' "$README"; then
    awk 'NR==1{print; print ""; print "Coatl follows an ancient, sleek serpent aesthetic: fluid paths, precise control, and minimal friction."; next}1' "$README" > "$README.tmp"
    mv "$README.tmp" "$README"
  fi
fi
if [[ -f "$README" && "$MODE" == "dry-run" ]]; then
  log "[dry-run] check/update '$README' branding motif"
fi

# VS Code / LSP package metadata alignment.
while IFS= read -r pkg; do
  if [[ "$MODE" == "dry-run" ]]; then
    log "[dry-run] inspect/update '$pkg' displayName + contributes"
    continue
  fi
  if [[ -n "$BACKUP_EXT" ]]; then
    cp "$pkg" "$pkg$BACKUP_EXT"
  fi
  if command -v jq >/dev/null 2>&1; then
    tmp="${pkg}.tmp"
    jq '(.displayName? // "Coatl") as $d
        | .displayName = (if ($d|type)=="string" then ($d | gsub("(?<![A-Za-z0-9_])Coatl(?![A-Za-z0-9_])";"Coatl") | gsub("(?<![A-Za-z0-9_])coatl(?![A-Za-z0-9_])";"coatl")) else "Coatl" end)
        | if .contributes? then (.contributes |= .) else . end' "$pkg" > "$tmp" && mv "$tmp" "$pkg"
  else
    if [[ -n "$BACKUP_EXT" ]]; then
      perl -i"$BACKUP_EXT" -pe 's/"displayName"\s*:\s*"[^"]*"/"displayName": "Coatl"/g; s/\bMee\b/Coatl/g; s/\bmee\b/coatl/g' "$pkg"
    else
      perl -i -pe 's/"displayName"\s*:\s*"[^"]*"/"displayName": "Coatl"/g; s/\bMee\b/Coatl/g; s/\bmee\b/coatl/g' "$pkg"
    fi
  fi
  log "[ok] updated '$pkg'"
done < <(cd "$ROOT_DIR" && rg --files -g '**/package.json')

log "done ($MODE)"
