# Surf Fountain

Fast. Private. Powerful.

A native Android browser, built and released entirely from a phone —
Termux + GitHub + GitHub Actions, no Android Studio, no desktop, no local
SDK, ever.

This is **Phase 0**: a real, working MVP, not a mockup. Everything below is
actual functioning code — WebView-based multi-tab browsing, bookmarks,
history, settings, a native New Tab page, an app icon done properly, and a
CI/release pipeline with the signing setup that makes "package conflicts on
update" structurally impossible. The bigger subsystems from the full Surf
Fountain spec (ad/tracker blocking, the Content Downloader, dev tools,
password manager, sync, the PDL AI assistant) come in after this, one at a
time — see [docs/ROADMAP.md](docs/ROADMAP.md).

## Quick start (Termux)

```bash
pkg install git
git clone https://github.com/<you>/<repo>.git surf-fountain
cd surf-fountain
scripts/setup.sh              # installs gh, sets up git + GitHub auth
scripts/create_keystore.sh    # one-time signing key — see docs/SIGNING.md
#  ↳ add the 4 secrets it prints under
#    Settings → Secrets and variables → Actions on GitHub
git push
scripts/build.sh              # triggers CI, streams logs, downloads the APK
```

Every real build happens on a GitHub Actions runner. This device only ever
edits files and runs `git`/`gh` — see [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)
for the full walkthrough.

## What's actually implemented

- Multi-tab browsing on Android System WebView — one WebView reused across
  tabs (save/restore on switch), address bar with URL-vs-search detection,
  back/forward/reload, per-tab loading progress
- Native New Tab page (search box + most-visited), not a loaded webpage
- Bookmarks and History, backed by Room, with search-ready schemas
- Settings: theme (system/light/dark, plus Material You dynamic color),
  home page
- The Surf Fountain icon, done as a proper adaptive icon (see
  [docs/ICON.md](docs/ICON.md) for why it's not just the source PNG dropped in)
- MVVM + Repository pattern + Hilt DI + Coroutines/Flow/StateFlow + Room +
  DataStore + Jetpack Compose + Material 3 + Navigation Compose, matching
  the architecture the full spec calls for
- CI (lint + unit tests + debug build on every push), a release pipeline
  (signed APK → GitHub Release, by tag or manual dispatch), and a nightly
  build — all in [.github/workflows](.github/workflows)
- The signing setup in `app/build.gradle.kts` that fixes "package appears
  to be corrupt" / "package conflicts with an existing package" for good —
  see [docs/SIGNING.md](docs/SIGNING.md)

## What's intentionally not here yet

Chrome extension support **cannot** work on Android System WebView — see
docs/ROADMAP.md for why, and what a native ad/tracker-blocking engine gets
you instead. FountainSurf (the in-house search engine) and PDL AI (the
built-in assistant) both need a live backend somewhere, which nothing in a
phone-only workflow hosts — Phase 0 uses DuckDuckGo as the real, working
default and leaves the plug-in points ready. Everything else from the full
spec — Download Manager, Content Downloader, dev tools, extensions
architecture (the parts of it that *are* possible on WebView), password
manager, sync, reader mode, and the rest — is sequenced in
[docs/ROADMAP.md](docs/ROADMAP.md).

## Project structure

```
app/src/main/java/com/surffountain/browser/
├── browser/          tabs, WebView management, address bar, tab switcher
├── home/             native New Tab page
├── bookmarks/        bookmarks screen + data
├── history/          history screen + data
├── settings/         settings screen + data
├── data/
│   ├── local/         Room entities + DAOs + database
│   ├── repository/     repository layer between UI and Room
│   └── preferences/    DataStore-backed settings
├── ui/
│   ├── theme/          Material 3 theme (purple/black, dynamic color)
│   └── navigation/      NavHost + destinations
└── di/                Hilt modules
```

Single Gradle module (`:app`) for now, organized in feature packages that
map cleanly onto Gradle modules later (`:feature:browser`, `:core:data`,
etc.) once the codebase is big enough that build-time modularity actually
pays for itself — splitting now would just slow down CI for no benefit yet.

## Scripts

| Script | What it does |
|---|---|
| `scripts/setup.sh` | One-time Termux environment setup |
| `scripts/create_keystore.sh` | One-time signing key generation |
| `scripts/build.sh` | Trigger CI, stream logs, download the debug APK |
| `scripts/release.sh` | Trigger a signed release build + GitHub Release |
| `scripts/version.sh` | Bump the versionName |
| `scripts/status.sh` | List recent workflow runs |
| `scripts/clean.sh` | Clear locally-downloaded artifacts |
| `scripts/install_hooks.sh` | Installs a pre-commit hook that blocks accidentally committing the keystore |

## Requirements

- minSdk 29 (Android 10) · targetSdk / compileSdk 36 (Android 16)
- Kotlin 2.0.21 · AGP 8.13.2 · Gradle 8.13 (pinned in `.github/workflows/*.yml` — see docs/SIGNING.md if a workflow's first step ever fails on this)
