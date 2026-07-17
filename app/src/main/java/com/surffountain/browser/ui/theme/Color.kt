package com.surffountain.browser.ui.theme

import androidx.compose.ui.graphics.Color

// Core brand palette, taken directly from the app icon so the UI and the
// launcher icon read as the same product.
val FountainPurple = Color(0xFF8B5CF6)
val FountainPurpleDark = Color(0xFF6D28D9)
val FountainPurpleLight = Color(0xFFC4B5FD)
val FountainVioletContainer = Color(0xFF4C1D95)

// Second brand accent — deliberately semantic, not decorative: the
// blocked-trackers count, the New Tab gradient, and "something needs your
// attention" badges all lean on this rather than sprinkling red anywhere
// it doesn't mean something.
val FountainRed = Color(0xFFEF4444)
val FountainRedLight = Color(0xFFFCA5A5)
val FountainRedDark = Color(0xFFB91C1C)
val FountainOrange = Color(0xFFF97316) // the purple->red gradient's midpoint

val PureBlack = Color(0xFF000000)
val NearBlackSurface = Color(0xFF121212)
val NearBlackSurfaceElevated = Color(0xFF1C1B1F)
val PureWhite = Color(0xFFFFFFFF)
val OffWhiteSurface = Color(0xFFFAF9FC)

val DangerRed = FountainRedDark
