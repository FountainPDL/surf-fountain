#!/usr/bin/env bash
# release.sh — trigger a signed release build + GitHub Release.
#
#   scripts/release.sh            manual build, published as a prerelease
#   scripts/release.sh v0.2.0     tags v0.2.0, published as a real release

set -euo pipefail

if [ "$#" -ge 1 ]; then
  TAG="$1"
  echo "Tagging $TAG and pushing..."
  git tag "$TAG"
  git push origin "$TAG"
  echo "release.yml starts automatically from the tag push. Watch it with: gh run watch"
else
  echo "No tag given — triggering a manual prerelease build instead."
  read -rp "Release notes (optional): " NOTES
  gh workflow run release.yml -f release_notes="$NOTES"
  sleep 5
  RUN_ID="$(gh run list --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
  gh run watch "$RUN_ID" --exit-status
fi
