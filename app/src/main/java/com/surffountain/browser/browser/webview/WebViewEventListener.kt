package com.surffountain.browser.browser.webview

import android.graphics.Bitmap

/**
 * Decouples SurfFountainWebViewClient/SurfFountainWebChromeClient (which
 * must extend Android framework classes) from whatever owns the tab state
 * — BrowserViewModel implements this rather than the clients holding a
 * direct ViewModel reference.
 */
interface WebViewEventListener {
    fun onPageStarted(url: String)
    fun onPageFinished(url: String, title: String?)
    fun onProgressChanged(progress: Int)
    fun onReceivedTitle(title: String)
    fun onReceivedIcon(icon: Bitmap?)
    /** A sub-resource request was blocked by Shields. Called off the main
     *  thread — see SurfFountainWebViewClient.shouldInterceptRequest. */
    fun onRequestBlocked(host: String)
}
