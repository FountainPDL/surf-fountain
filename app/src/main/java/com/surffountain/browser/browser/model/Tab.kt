package com.surffountain.browser.browser.model

import android.graphics.Bitmap
import android.os.Bundle

/**
 * In-memory tab state. Deliberately separate from [TabEntity][com.surffountain.browser.data.local.entity.TabEntity],
 * which is the persisted subset (no Bitmap, no WebView Bundle — see that
 * class's kdoc for why).
 */
data class Tab(
    val id: String,
    val url: String = "",
    val title: String = "",
    val isPrivate: Boolean = false,
    val favicon: Bitmap? = null,
    val webViewState: Bundle? = null,
    val isLoading: Boolean = false,
    val progress: Int = 0,
    /**
     * Bumped only by explicit navigation (address bar submit, bookmark tap,
     * Home button, new tab) — never by the WebView's own onPageStarted/
     * onPageFinished callbacks. BrowserScreen's LaunchedEffect keys on this
     * alongside [id] so it can tell "the user asked to go somewhere new"
     * apart from "the page the WebView is already loading reported its
     * own progress," without which every in-page link click would
     * re-trigger a redundant loadUrl() on the page it's already loading.
     */
    val navigationRequestId: Int = 0,
    /** Ads/trackers blocked on the current page load. Reset to 0 in
     *  BrowserViewModel.onPageStarted, incremented via onRequestBlocked. */
    val blockedCount: Int = 0
)
