# The icon

## What changed from the source file

The source artwork (the full lockup: emblem + "SURF FOUNTAIN" wordmark +
"FAST • PRIVATE • POWERFUL" tagline) isn't used directly as the launcher
icon. Two reasons:

1. **Android masks launcher icons into different shapes** per launcher —
   circle, squircle, rounded square, sometimes a teardrop — via the
   adaptive icon system. Anything not comfortably within the centered
   "safe zone" (roughly the inner 61% of the icon canvas) gets clipped
   unpredictably depending on the device. The wordmark, sitting near the
   bottom edge of the source square, would be cut off on a lot of real
   devices.
2. **The launcher already renders the app's name as a separate text label**
   underneath the icon. Baking "Surf Fountain" into the icon image itself
   means the name effectively appears twice, and the second copy is the
   one that gets clipped.

## What's actually in the repo

- `app/src/main/res/mipmap-{density}/ic_launcher_foreground.png` — just the
  emblem (the S / wave / globe mark), cropped out of the source image,
  recentered, and padded so it sits safely inside the mask safe-zone at
  every density Android needs (mdpi through xxxhdpi).
- `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (+ `_round.xml`) —
  the adaptive icon definition: that foreground layer over a solid black
  background (`@color/ic_launcher_background`, matching the source
  artwork's own canvas). `minSdk` is 29, so every device this app can run
  on supports this — there's no legacy flat-PNG fallback to also generate.
- `assets/play_store_icon_512.png` — the full lockup (emblem + wordmark),
  512×512, for the Play Store listing / marketing use, where the wordmark
  belongs and won't get clipped.
- `assets/icon_foreground_master_1024.png` — a large, transparent-background
  version of just the emblem, kept around for re-exporting at other sizes
  later (splash screens, notification icons, etc.) without having to
  re-derive the crop from the original source file again.

## Where the emblem-only version shows up elsewhere

The splash screen (`Theme.SurfFountain.Starting` in
`app/src/main/res/values/themes.xml`) reuses the same
`ic_launcher_foreground` asset via `windowSplashScreenAnimatedIcon` — the
platform convention for what a splash icon should be is the same "just the
mark, safely inset" shape as an adaptive icon foreground, so this doubles
as that with no extra asset needed.
