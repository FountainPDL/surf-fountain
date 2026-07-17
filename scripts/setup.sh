#!/usr/bin/env bash
# setup.sh — one-time Termux environment setup for working on Surf Fountain.
#
# You do NOT need Android Studio, a local Android SDK, or Gradle installed
# anywhere for this. All real compilation happens on GitHub Actions
# runners. This only sets up the two CLI tools you need on-device: git (to
# edit/commit/push) and gh (to trigger/watch/download workflow runs
# without leaving the terminal).

set -euo pipefail

echo "== Surf Fountain / Termux setup =="

if command -v pkg >/dev/null 2>&1; then
  pkg update -y
  pkg install -y git gh
else
  echo "This doesn't look like Termux (no 'pkg' command found)."
  echo "Install git and the GitHub CLI (gh) with your system's package manager, then re-run."
fi

echo
echo "-- git identity --"
if [ -z "$(git config --global user.email || true)" ]; then
  read -rp "Git email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
if [ -z "$(git config --global user.name || true)" ]; then
  read -rp "Git name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

echo
echo "-- GitHub authentication --"
if ! gh auth status >/dev/null 2>&1; then
  echo "Opening GitHub CLI login (choose HTTPS, then 'Login with a web browser')..."
  gh auth login
else
  echo "Already logged in as $(gh api user --jq .login 2>/dev/null || echo '(unknown)')."
fi

echo
echo "Setup done. Next steps:"
echo "   1. scripts/create_keystore.sh   (one-time signing key setup — see docs/SIGNING.md)"
echo "   2. add the four SF_* secrets it prints under Settings > Secrets and variables > Actions"
echo "   3. git push, then scripts/build.sh"
