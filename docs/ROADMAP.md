# Roadmap

Phase 0 (this codebase) is a genuine MVP, not a skeleton with everything
stubbed out. Everything after it lands the same way: real, working code
each time, nothing marked "done" that isn't.

## Phase 0 — done

Core browser shell: tabs, address bar, back/forward/reload, native New Tab
page, bookmarks, history, settings (theme + home page), the icon done as a
proper adaptive icon, and the CI/release/signing pipeline described in
[SIGNING.md](SIGNING.md).

## Suggested order for what's next

1. **Download Manager + Content Downloader** — the flagship, most unique
   feature in the original spec. Needs `DownloadManager`/`WorkManager` for
   background downloads and a page-asset-scanning `Content Downloader` menu.
2. **Privacy / Shields** — ad + tracker blocking, cookie controls, HTTPS
   upgrade, site permissions. This is also where the network security
   config's cleartext-allowed default gets a real enforcement layer instead
   of just "not blocked at the OS level."
3. **Tab features** — groups, pinning, muting, search, private tabs (the
   data model already has `isPrivate` wired through; Phase 0 just never
   exposed a way to create one).
4. **Reader Mode** — self-contained, no backend needed, good return on effort.
5. **Password Manager** — encrypted storage + biometric unlock + autofill.
6. **Developer Tools** — view source, inspect, console, network — WebView
   exposes enough via `WebView.setWebContentsDebuggingEnabled` and
   `evaluateJavascript` to build a real (if WebView-scoped, not full
   Chromium DevTools Protocol) version of this.
7. **Search** — multi-engine picker (Google/Bing/DuckDuckGo/Brave
   Search/Startpage/SearXNG/custom), voice search, suggestions.
8. **Sync** — needs a backend decision first (self-hosted vs. a service);
   nothing to build in-app until that's settled.
9. **FountainSurf** and **PDL AI** — see below.
10. **Extensions** — see below; likely never in the form originally spec'd.

## Two features that need a scope change, and why

### Chrome extension support

Android System WebView has no extension API at all — not partial, not
limited. Real Chrome/Manifest V2/V3 extension support only exists in
browsers that fork Chromium itself and specifically engineer it in, the way
Brave, Vivaldi, and (until its solo maintainer stepped away in January
2026) Kiwi Browser do. That's browser-engine-vendor-level work — an
entirely different, vastly larger project than an app on top of WebView,
not something buildable or maintainable from Termux + GitHub Actions.

Realistic version: a strong native ad/tracker-blocking engine (item 2
above) covers most of what people actually reach for extensions to do.
`browser/webview/SurfFountainWebViewClient.kt` is deliberately structured
as the seam that kind of interception logic hooks into. If Chrome extension
support specifically is a hard requirement later, that's a Chromium-fork
project layered *alongside* Surf Fountain, not a feature added on top of
this codebase.

### FountainSurf and PDL AI

A real search engine (crawling, indexing, ranking) and a real AI assistant
both need a live backend server somewhere — nothing in a phone + Termux +
GitHub Actions workflow hosts one (GitHub Actions is CI/CD, not app
hosting). Realistic versions that *are* fully buildable as pure client work:

- **FountainSurf** becomes a polished picker across real engines
  (Google/Bing/DuckDuckGo/Brave Search/Startpage/SearXNG/custom URL) —
  which the original spec wants as a feature anyway — rather than a
  from-scratch search index.
- **PDL AI** calls a hosted LLM API (Anthropic's, OpenAI's, or similar)
  directly from the app with your own API key, the same way any app with
  an "AI features" toggle does it. Summarize/explain/translate/page-Q&A all
  work fine this way; it's a client calling an existing model, not standing
  up new infrastructure.

Both are real, shippable features under this framing — just not a
ground-up search engine or a self-hosted model.
