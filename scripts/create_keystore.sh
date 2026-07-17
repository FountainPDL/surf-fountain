#!/usr/bin/env bash
# create_keystore.sh — one-time signing key generation for Surf Fountain.
#
# Requires `keytool`, which ships with any JDK:
#   pkg install openjdk-17
#
# Run this exactly ONCE, ever. It creates surffountain.jks in the current
# directory (already covered by .gitignore — never commit it) and prints
# the four GitHub secret values to paste in at:
#   https://github.com/<you>/<repo>/settings/secrets/actions
#
# This is the fix for "package conflicts with an existing package" on
# update: every future debug and release build gets signed with this exact
# key, forever, so Android always recognizes a new build as a legitimate
# update rather than a different app.

set -euo pipefail

KEYSTORE_FILE="surffountain.jks"
ALIAS="surffountain"
VALIDITY_DAYS=10950   # 30 years — long enough you never have to redo this

if [ -f "$KEYSTORE_FILE" ]; then
  echo "$KEYSTORE_FILE already exists in this directory."
  echo "Re-running this would generate a DIFFERENT key and reintroduce the exact"
  echo "'package conflicts' problem this script exists to prevent. Aborting."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a JDK first:"
  echo "  pkg install openjdk-17"
  exit 1
fi

echo "This creates the ONE signing key Surf Fountain will use forever."
echo "Pick a password you can find again — losing it means starting a brand new"
echo "install identity from scratch for every future release."
echo

read -rsp "Keystore password (min 6 characters): " STORE_PASSWORD
echo
read -rsp "Confirm: " STORE_PASSWORD_CONFIRM
echo

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
  echo "Passwords didn't match — nothing was created. Try again."
  exit 1
fi

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE_FILE" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY_DAYS" \
  -storepass "$STORE_PASSWORD" \
  -keypass "$STORE_PASSWORD" \
  -dname "CN=Surf Fountain, OU=Personal, O=Surf Fountain, L=Unknown, S=Unknown, C=US"

echo
echo "=================================================================="
echo "$KEYSTORE_FILE created. Add these four secrets at:"
echo "  https://github.com/<you>/<repo>/settings/secrets/actions"
echo "=================================================================="
echo
echo "SF_KEYSTORE_BASE64:"
base64 -w 0 "$KEYSTORE_FILE" 2>/dev/null || base64 "$KEYSTORE_FILE"
echo
echo
echo "SF_KEYSTORE_PASSWORD   -> (the password you just typed)"
echo "SF_KEY_ALIAS           -> $ALIAS"
echo "SF_KEY_PASSWORD        -> (the same password again — one alias, kept simple)"
echo
echo "IMPORTANT: back up $KEYSTORE_FILE and the password somewhere safe outside"
echo "this device. If both are lost, there is no way to recover them — not by"
echo "Anthropic, not by GitHub, not by anyone — and every future release would"
echo "need a new identity, which brings back the exact update problem this"
echo "script exists to solve."
