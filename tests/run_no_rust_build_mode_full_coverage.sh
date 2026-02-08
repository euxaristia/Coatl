#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-no-rust-build-mode.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/cargo" <<'SH'
#!/usr/bin/env bash
echo "[FAIL] cargo should not be invoked in no-rust-build mode" >&2
exit 86
SH
chmod +x "$TMP_DIR/bin/cargo"
export PATH="$TMP_DIR/bin:$PATH"

unset COATL_NO_RUST || true
export COATL_IR_FIRST_BUILD=1

build_all_emit() {
  local emit="$1"
  local ext="$2"
  local failed=0
  while IFS= read -r src; do
    local out="$TMP_DIR/${emit}_$(basename "$src" .coatl).$ext"
    if ! "$ROOT_DIR/coatl" build "$ROOT_DIR/$src" -o "$out" >/dev/null 2>"$TMP_DIR/${emit}.err"; then
      failed=1
      echo "[FAIL] emit=$emit $src"
      sed -n '1,4p' "$TMP_DIR/${emit}.err"
    fi
  done < <(cd "$ROOT_DIR" && rg --files tests examples selfhost | rg '\.coatl$')
  if [[ "$failed" -ne 0 ]]; then
    exit 1
  fi
  echo "  ok (full corpus emit=$emit)"
}

echo "[no-rust-build-mode] default CLI full coverage"
build_all_emit wat wat
build_all_emit ir ir
build_all_emit asm s

echo "no-rust-build mode full coverage passed"
