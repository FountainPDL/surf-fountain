#!/usr/bin/env bash
# install_hooks.sh — installs a pre-commit hook that refuses to commit a
# keystore file by accident. Belt-and-suspenders on top of .gitignore.

set -euo pipefail

HOOK_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOK_DIR"

cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
if git diff --cached --name-only | grep -E '\.(jks|keystore)$' >/dev/null; then
  echo "Refusing to commit a .jks/.keystore file — that key must never be in git."
  echo "(It should only ever live as the SF_KEYSTORE_BASE64 GitHub secret.)"
  exit 1
fi
HOOK
chmod +x "$HOOK_DIR/pre-commit"

echo "pre-commit hook installed."
