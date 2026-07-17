#!/usr/bin/env bash
# build.sh — trigger the CI workflow (lint + unit tests + debug APK) on
# GitHub Actions and stream its logs, without leaving Termux. The actual
# Gradle/Android SDK work all happens on the runner, not on this device.

set -euo pipefail

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Triggering ci.yml on branch '$BRANCH'..."
gh workflow run ci.yml --ref "$BRANCH"

sleep 5
RUN_ID="$(gh run list --workflow=ci.yml --branch="$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')"
echo "Watching run $RUN_ID — Ctrl+C stops watching only, the build itself keeps going on GitHub."
gh run watch "$RUN_ID" --exit-status

mkdir -p ./downloads
gh run download "$RUN_ID" --dir ./downloads
echo "Debug APK and lint/test reports are in ./downloads"
