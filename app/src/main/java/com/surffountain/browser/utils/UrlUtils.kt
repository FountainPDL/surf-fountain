package com.surffountain.browser.utils

import java.net.URLEncoder

/**
 * Deliberately pure Kotlin — no android.util.Patterns or other framework
 * class — so address-bar resolution logic can be unit tested on the plain
 * JVM with no Robolectric/instrumentation setup required.
 */
object UrlUtils {

    private val schemeRegex = Regex("^[a-zA-Z][a-zA-Z0-9+.-]*://")
    private val domainRegex = Regex(
        "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+(:\\d+)?(/.*)?$"
    )
    private val ipRegex = Regex("^(\\d{1,3}\\.){3}\\d{1,3}(:\\d+)?(/.*)?$")

    /**
     * Resolves address-bar input into a URL to load: unchanged if it
     * already has a scheme, https-prefixed if it looks like a bare
     * domain/IP/localhost, otherwise wrapped as a query against
     * [searchTemplate] (a URL containing a literal "%s", e.g.
     * "https://duckduckgo.com/?q=%s").
     */
    fun resolveInput(input: String, searchTemplate: String): String {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return ""

        if (schemeRegex.containsMatchIn(trimmed)) return trimmed

        val looksLikeAddress = !trimmed.contains(" ") &&
            (domainRegex.matches(trimmed) || ipRegex.matches(trimmed) || trimmed.startsWith("localhost"))

        return if (looksLikeAddress) "https://$trimmed" else buildSearchUrl(trimmed, searchTemplate)
    }

    private fun buildSearchUrl(query: String, searchTemplate: String): String {
        val encoded = URLEncoder.encode(query, "UTF-8")
        return searchTemplate.replace("%s", encoded)
    }
}
