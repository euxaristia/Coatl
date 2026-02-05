#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-norust-bin-ir-no-cc.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

 prove_as_ld() {
  command -v as >/dev/null 2>&1 && command -v ld >/dev/null 2>&1
}

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "no-rust bin ir no-cc smoke currently supports Linux only"
  exit 1
fi

if ! prove_as_ld; then
  echo "skip: as+ld not available for no-cc bin smoke"
  exit 0
fi

mkdir -p "$TMP_DIR/bin"
for cc_name in cc gcc clang; do
  cat > "$TMP_DIR/bin/$cc_name" <<'SH'
#!/usr/bin/env bash
echo "blocked C compiler invocation in no-cc bin smoke" >&2
exit 127
SH
  chmod +x "$TMP_DIR/bin/$cc_name"
done

echo "[no-rust-bin-ir-no-cc] hello"
HELLO_BIN="$TMP_DIR/hello.bin"
PATH="$TMP_DIR/bin:$PATH" COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/examples/hello.coatl" --emit=bin --toolchain=ir -o "$HELLO_BIN"
hello_out="$("$HELLO_BIN")"
hello_rc=$?
if [[ "$hello_out" != "Hello, world!" ]]; then
  echo "[FAIL] hello output mismatch"
  printf 'got: %q\n' "$hello_out"
  exit 1
fi
if [[ "$hello_rc" -ne 0 ]]; then
  echo "[FAIL] hello rc mismatch: $hello_rc"
  exit 1
fi

echo "[no-rust-bin-ir-no-cc] mem_test"
MEM_BIN="$TMP_DIR/mem.bin"
PATH="$TMP_DIR/bin:$PATH" COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/tests/mem_test.coatl" --emit=bin --toolchain=ir -o "$MEM_BIN"
set +e
"$MEM_BIN" >/dev/null 2>&1
mem_rc=$?
set -e
if [[ "$mem_rc" -ne 142 ]]; then
  echo "[FAIL] mem_test rc mismatch: $mem_rc"
  exit 1
fi

echo "no-rust bin ir no-cc smoke passed"
