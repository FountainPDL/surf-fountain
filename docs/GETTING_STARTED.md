# Getting started from Termux

The whole point of this setup: nothing here ever needs Android Studio, a
local Android SDK, or a desktop computer. This device edits files and runs
`git`/`gh`; every real Gradle/Android-SDK build happens on a GitHub Actions
runner.

## 1. Install Termux

From F-Droid, not the Play Store listing (that one stopped receiving
updates years ago and is missing packages this workflow needs).

## 2. Clone the repo

```bash
pkg install git
git clone https://github.com/<you>/<repo>.git surf-fountain
cd surf-fountain
```

## 3. Run setup once

```bash
scripts/setup.sh
```

Installs the GitHub CLI (`gh`), sets your git identity if it isn't already
configured, and walks you through `gh auth login` (pick HTTPS, then
"Login with a web browser" — it gives you a code to enter on
github.com/login/device from any browser, including on this phone).

## 4. Create your signing key once

```bash
scripts/create_keystore.sh
```

Requires a JDK for `keytool` — `pkg install openjdk-17` first if you don't
have one. Full explanation of what this is and why it matters:
[SIGNING.md](SIGNING.md). Add the four secrets it prints to
`Settings → Secrets and variables → Actions` on your GitHub repo, then:

```bash
git push
```

## 5. Everyday loop

Edit files with any editor (`nano`, `vim`, or generate whole files with
`cat > path/to/File.kt << 'EOF' ... EOF` heredocs — no editor needed at
all for that), then:

```bash
git add -A
git commit -m "what changed"
git push
scripts/build.sh
```

`build.sh` triggers the CI workflow, streams its logs right there in your
terminal, and downloads the resulting debug APK into `./downloads` when it
finishes. Open that APK from a file manager to install/update it on this
same device.

## 6. Cutting a release

```bash
scripts/version.sh 0.2.0     # bumps the human-readable version string
git add -A && git commit -m "Bump to 0.2.0"
git push
scripts/release.sh v0.2.0    # tags it, publishes a signed GitHub Release
```

Or `scripts/release.sh` with no argument for a one-off signed prerelease
build without tagging anything.

## Troubleshooting

- **`gh: command not found`** — re-run `scripts/setup.sh`, or your Termux
  package index may need `pkg update` first.
- **A workflow fails on its very first Gradle step** — see the last
  section of [SIGNING.md](SIGNING.md); it's almost always the pinned
  Gradle version needing a small bump.
- **"package conflicts with an existing package" on install** — this is
  the whole reason [SIGNING.md](SIGNING.md) and `scripts/create_keystore.sh`
  exist; if you're seeing it, the secrets likely aren't set up yet.
