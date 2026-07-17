#!/usr/bin/env bash
# status.sh — quick look at recent workflow runs without opening a browser.
set -euo pipefail
gh run list --limit 10
