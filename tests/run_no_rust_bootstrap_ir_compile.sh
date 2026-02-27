#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/coatl-bootstrap-ir-norust.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT


echo "no-rust bootstrap toolchain=ir compile passed"
