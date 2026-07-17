#!/usr/bin/env bash
# clean.sh — clear locally-downloaded build artifacts. There's no local
# Gradle build directory to clean here — nothing is ever built on-device.
set -euo pipefail
rm -rf ./downloads
echo "Cleared ./downloads"
