#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-no-c-selfhost.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required but not found in PATH"
  exit 1
fi

mkdir -p "$TMP_DIR/bin"
for cc_name in cc gcc clang; do
  cat > "$TMP_DIR/bin/$cc_name" <<'SH'
#!/usr/bin/env bash
echo "blocked C compiler invocation in no-C smoke test" >&2
exit 127
SH
  chmod +x "$TMP_DIR/bin/$cc_name"
done

BOOTSTRAP_WAT="$TMP_DIR/bootstrap-no-c.wat"
COATL_NO_RUST=1 COATL_IR_FIRST_BUILD=1 PATH="$TMP_DIR/bin:$PATH" \
  "$ROOT_DIR/coatl" build "$ROOT_DIR/selfhost/bootstrap.coatl" --emit=wat --toolchain=auto -o "$BOOTSTRAP_WAT"

if [[ ! -s "$BOOTSTRAP_WAT" ]]; then
  echo "[FAIL] bootstrap WAT was not produced"
  exit 1
fi
if ! head -n 1 "$BOOTSTRAP_WAT" | grep -Fq "(module"; then
  echo "[FAIL] bootstrap output is not a WAT module"
  exit 1
fi

echo "no-C-compiler selfhost bootstrap smoke passed"
