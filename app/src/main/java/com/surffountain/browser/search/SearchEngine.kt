package com.surffountain.browser.search

/**
 * The real, buildable version of "FountainSurf": a picker across actual
 * search providers rather than a from-scratch search index (which needs a
 * live backend nothing in this workflow hosts — see docs/ROADMAP.md).
 * template contains a literal "%s" for the query, consumed by
 * UrlUtils.resolveInput.
 */
enum class SearchEngine(val displayName: String, val template: String) {
    DUCKDUCKGO("DuckDuckGo", "https://duckduckgo.com/?q=%s"),
    GOOGLE("Google", "https://www.google.com/search?q=%s"),
    BING("Bing", "https://www.bing.com/search?q=%s"),
    BRAVE_SEARCH("Brave Search", "https://search.brave.com/search?q=%s"),
    STARTPAGE("Startpage", "https://www.startpage.com/sp/search?query=%s"),
    ECOSIA("Ecosia", "https://www.ecosia.org/search?q=%s"),
    YAHOO("Yahoo", "https://search.yahoo.com/search?p=%s");

    companion object {
        fun fromTemplate(template: String): SearchEngine? = values().find { it.template == template }
    }
}
