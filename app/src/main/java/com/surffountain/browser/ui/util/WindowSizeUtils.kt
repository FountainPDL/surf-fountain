package com.surffountain.browser.ui.util

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.dp

enum class WindowWidthClass { COMPACT, MEDIUM, EXPANDED }

/**
 * Plain screenWidthDp thresholds (Google's own published breakpoints —
 * 600dp / 840dp) rather than a dedicated window-size-class library: zero
 * new dependencies, and this is worth keeping boringly simple to get right
 * on the first try rather than clever.
 */
@Composable
fun rememberWindowWidthClass(): WindowWidthClass {
    val widthDp = LocalConfiguration.current.screenWidthDp
    return when {
        widthDp < 600 -> WindowWidthClass.COMPACT
        widthDp < 840 -> WindowWidthClass.MEDIUM
        else -> WindowWidthClass.EXPANDED
    }
}

/**
 * Caps list/form content to a readable width and centers it on tablets and
 * unfolded foldables, instead of a single-column list stretching edge to
 * edge across a 10" screen. The browser's own WebView content deliberately
 * does NOT use this — a loaded page should get the full width available,
 * same as any browser on a tablet.
 */
@Composable
fun AdaptiveContentWidth(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier = modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Box(modifier = Modifier.widthIn(max = 720.dp)) {
            content()
        }
    }
}
