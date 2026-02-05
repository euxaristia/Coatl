#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/mee-bootstrap-ir-norust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MEE_NO_RUST=1 "$ROOT_DIR/mee" build "$ROOT_DIR/selfhost/bootstrap.mee" --emit=wat --toolchain=ir -o "$TMP_DIR/bootstrap.wat"

echo "no-rust bootstrap toolchain=ir compile passed"
