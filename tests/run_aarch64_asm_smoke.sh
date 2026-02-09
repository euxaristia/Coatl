#!/usr/bin/env bash
# Test that aarch64 assembly output can be assembled
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -m)" != "aarch64" ]]; then
  echo "SKIP: not running on aarch64"
  exit 0
fi

if ! command -v as >/dev/null 2>&1; then
  echo "SKIP: GNU as not available"
  exit 0
fi

echo "Testing aarch64 assembly generation and assembly..."

# Create a simple test program
cat > /tmp/aarch64_asm_test.coatl << 'EOF'
fn main() -> i32 {
  let x: i32 = 42;
  return x;
}
EOF

# Generate assembly
./coatl build /tmp/aarch64_asm_test.coatl --arch=aarch64 --toolchain=ir -o /tmp/aarch64_asm_test.s 2>&1
if [[ ! -f /tmp/aarch64_asm_test.s ]]; then
  echo "FAIL: assembly file not generated"
  exit 1
fi

# Try to assemble it
if ! as /tmp/aarch64_asm_test.s -o /tmp/aarch64_asm_test.o 2>&1; then
  echo "FAIL: assembly failed to assemble"
  echo "--- Generated assembly (first 50 lines) ---"
  head -50 /tmp/aarch64_asm_test.s
  exit 1
fi

echo "PASS: aarch64 assembly generated and assembled successfully"

# Cleanup
rm -f /tmp/aarch64_asm_test.coatl /tmp/aarch64_asm_test.s /tmp/aarch64_asm_test.o
