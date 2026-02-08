#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-bootstrap-ir-norust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

COATL_NO_RUST=1 "$ROOT_DIR/coatl" build "$ROOT_DIR/selfhost/bootstrap.coatl" --toolchain=ir -o "$TMP_DIR/bootstrap.wat"

echo "no-rust bootstrap toolchain=ir compile passed"
