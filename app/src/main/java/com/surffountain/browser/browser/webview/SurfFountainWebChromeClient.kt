package com.surffountain.browser.browser.webview

import android.graphics.Bitmap
import android.webkit.WebChromeClient
import android.webkit.WebView

class SurfFountainWebChromeClient(
    private val listener: WebViewEventListener
) : WebChromeClient() {

    override fun onProgressChanged(view: WebView?, newProgress: Int) {
        super.onProgressChanged(view, newProgress)
        listener.onProgressChanged(newProgress)
    }

    override fun onReceivedTitle(view: WebView?, title: String?) {
        super.onReceivedTitle(view, title)
        title?.let(listener::onReceivedTitle)
    }

    override fun onReceivedIcon(view: WebView?, icon: Bitmap?) {
        super.onReceivedIcon(view, icon)
        listener.onReceivedIcon(icon)
    }
}
