package com.surffountain.browser.browser.webview

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import com.surffountain.browser.privacy.AdBlockEngine
import java.io.ByteArrayInputStream

/**
 * Phase 0 policy (still true): let the WebView handle http/https itself,
 * hand any other scheme (tel:, mailto:, market:, intent:, ...) to the OS.
 *
 * Shields: [shouldInterceptRequest] runs on a background thread (WebView's
 * own contract, not a choice made here) for every sub-resource a page
 * loads. Main-frame navigations are never blocked here — only a site's own
 * sub-resources — so typing a tracker's domain directly still loads
 * something instead of a blank page.
 *
 * Downloads: a URL ending in a well-known download-only extension (.pdf,
 * .zip, .apk, ...) is intercepted here, BEFORE the WebView ever attempts
 * to navigate to it. That's the fix for the black-screen/reload-loop bug —
 * letting WebView actually start "loading" a URL that's really a file
 * download (rather than a page) is what left it stuck showing nothing.
 * setDownloadListener (BrowserScreen) remains the fallback for downloads
 * that only reveal themselves via a Content-Disposition header — a
 * dynamic URL with no file extension in the path.
 */
class SurfFountainWebViewClient(
    private val listener: WebViewEventListener,
    private val isShieldsEnabled: () -> Boolean,
    private val allowlistForCurrentSite: () -> Set<String> = { emptySet() },
    private val onDownloadUrl: (url: String) -> Unit
) : WebViewClient() {

    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        url?.let(listener::onPageStarted)
    }

    override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        url?.let { listener.onPageFinished(it, view?.title) }
    }

    override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
        if (request == null || request.isForMainFrame) {
            return super.shouldInterceptRequest(view, request)
        }
        val host = request.url?.host
        return if (AdBlockEngine.isBlocked(host, isShieldsEnabled(), allowlistForCurrentSite())) {
            listener.onRequestBlocked(host.orEmpty())
            WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
        } else {
            super.shouldInterceptRequest(view, request)
        }
    }

    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
        val uri = request?.url ?: return false
        return when (uri.scheme) {
            "http", "https" -> {
                if (isLikelyDownload(uri.path)) {
                    onDownloadUrl(uri.toString())
                    true
                } else {
                    false
                }
            }
            else -> {
                try {
                    view?.context?.startActivity(Intent(Intent.ACTION_VIEW, uri))
                } catch (_: ActivityNotFoundException) {
                    // No app can handle it — silently ignore rather than crash.
                }
                true
            }
        }
    }

    private fun isLikelyDownload(path: String?): Boolean {
        val lower = path?.lowercase() ?: return false
        return DOWNLOAD_EXTENSIONS.any { lower.endsWith(it) }
    }

    companion object {
        private val DOWNLOAD_EXTENSIONS = listOf(
            ".pdf", ".zip", ".rar", ".7z", ".apk", ".exe", ".dmg", ".iso",
            ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx"
        )
    }
}
