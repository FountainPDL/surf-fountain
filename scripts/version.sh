#!/usr/bin/env bash
# version.sh — bump the human-readable versionName ("0.1.0"). versionCode
# (the integer Android actually compares to decide "is this newer?") is
# handled automatically by CI from GITHUB_RUN_NUMBER — see app/build.gradle.kts
# — so this script is only ever about the number people see, never the one
# that affects whether an update installs.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: scripts/version.sh 0.2.0"
  exit 1
fi

NEW_VERSION="$1"
FILE="app/build.gradle.kts"

sed -i.bak -E "s/versionName = \"[^\"]+\"/versionName = \"$NEW_VERSION\"/" "$FILE"
rm -f "$FILE.bak"

echo "versionName is now $NEW_VERSION."
grep versionName "$FILE"
echo "Commit this, then run: scripts/release.sh v$NEW_VERSION"
