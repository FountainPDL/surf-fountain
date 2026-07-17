# Signing, and why updates won't conflict

## The problem this solves

Android refuses to install an APK "update" over an app that's already on
the device unless the new APK is signed with the **exact same certificate**
as the one already installed. That's not a bug, it's the platform's core
security model — it's what stops someone else from shipping a fake update
to an app they don't own.

The most common way to accidentally violate this on your own app: if you
never configure signing explicitly, the Android Gradle Plugin quietly signs
debug builds with a "debug keystore" it auto-generates the first time it's
needed. On a normal desktop, that file lives at `~/.android/debug.keystore`
and sticks around, so every local build keeps using the same one. But a
GitHub Actions runner is a **brand new, disposable machine every single
run** — nothing persists between workflow runs unless you explicitly save
it. Left on autopilot, that means every CI build generates a *new* random
debug keystore, so every "update" is actually signed with a different key
than the last one — which is exactly the "package appears to be corrupt" /
"package conflicts with an existing package" error.

## The fix

One keystore, generated once, stored as a GitHub secret, decoded fresh at
the start of every workflow run, used to sign every build — debug and
release alike — forever. See `app/build.gradle.kts`'s `signingConfigs`
block and the "Configure signing" step near the top of each workflow in
`.github/workflows/`.

Debug and release builds get **different `applicationId`s**
(`com.surffountain.browser.debug` vs `com.surffountain.browser`) so they
can coexist on your device as two separate apps without ever conflicting
with *each other* — but each one individually stays perfectly consistent
release after release, which is the part that actually matters here.

## One-time setup

```bash
scripts/create_keystore.sh
```

This prints four values. Add them at
`https://github.com/<you>/<repo>/settings/secrets/actions` as **repository
secrets** (not variables — secrets are encrypted and never shown in logs):

| Secret | Value |
|---|---|
| `SF_KEYSTORE_BASE64` | the long base64 blob the script prints |
| `SF_KEYSTORE_PASSWORD` | the password you typed into the script |
| `SF_KEY_ALIAS` | `surffountain` |
| `SF_KEY_PASSWORD` | the same password again |

Until these four secrets exist, CI still builds successfully — it just
falls back to AGP's default (unstable-across-runs) debug signing for debug
builds, and a release build fails on purpose with a clear error rather than
silently producing something that can never be a real update chain. Once
the secrets are added, every subsequent run — debug, release, or nightly —
is stable from that point forward.

**Never commit the `.jks`/`.keystore` file itself.** It's already covered
by `.gitignore`, and `scripts/install_hooks.sh` adds a pre-commit hook that
refuses the commit as a second line of defense. Keep a backup of the file
and its password somewhere safe outside this device — if both are lost,
there's no way to recover them, and every future release would need to
start a brand new install identity, bringing back the exact problem this
whole setup exists to prevent.

## Other, smaller causes of the same symptom

Signing is the big one, but two other things produce a similar-looking
failure and are worth knowing about:

- **`applicationId` changing.** It's pinned to `com.surffountain.browser`
  in `app/build.gradle.kts` and should never change once you've installed
  a build from it — a different applicationId isn't "the same app
  updating," it's a new app to Android.
- **`versionCode` not increasing.** Some install flows reject an "update"
  whose versionCode isn't strictly greater than what's installed.
  `versionCode` is set from `GITHUB_RUN_NUMBER` automatically, so this
  can't happen by accident — you never have to remember to bump it (that's
  what `scripts/version.sh` is for instead: it only touches the
  human-readable `versionName`, which doesn't affect installability at all).

## If the very first CI run fails

The Gradle version is pinned explicitly (`gradle-version: '8.13'` in each
workflow) rather than left as "latest," because AGP 8.x and Gradle 9.x
don't pair with each other. If a workflow's very first real step —
"Set up Gradle" or the build step right after it — is what fails, that
version pin is the one thing most likely to need a small bump. The error
GitHub Actions prints will say exactly which Gradle version range AGP wants;
update the `gradle-version` line in the relevant `.github/workflows/*.yml`
file to match.
