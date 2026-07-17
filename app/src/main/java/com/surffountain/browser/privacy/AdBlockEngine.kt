package com.surffountain.browser.privacy

/**
 * Domain-level ad/tracker blocking — Shields' engine. Deliberately
 * suffix-matching against a curated domain list only: no cosmetic
 * (element-hiding) rules, no path-pattern rules, no full EasyList/
 * EasyPrivacy filter-syntax parser. That's real, scoped future work (see
 * docs/ROADMAP.md) — domain-level blocking alone is what actually stops a
 * request from ever going out, and covers most of the practical benefit
 * people reach for a blocker for in the first place.
 */
object AdBlockEngine {

    // Ad-serving / bidding networks.
    private val adDomains = setOf(
        "doubleclick.net",
        "googlesyndication.com",
        "googleadservices.com",
        "adservice.google.com",
        "amazon-adsystem.com",
        "criteo.com",
        "criteo.net",
        "adnxs.com",
        "pubmatic.com",
        "rubiconproject.com",
        "openx.net",
        "casalemedia.com",
        "outbrain.com",
        "taboola.com",
        "moatads.com",
        "adsafeprotected.com",
        "adform.net",
        "adroll.com",
        "media.net",
        "yieldmo.com",
        "smartadserver.com",
        "bidswitch.net",
        "contextweb.com",
        "sharethrough.com",
        "33across.com",
        "indexexchange.com",
        "spotxchange.com",
        "teads.tv",
    )

    // Analytics / behavioral tracking / fingerprinting.
    private val trackerDomains = setOf(
        "google-analytics.com",
        "scorecardresearch.com",
        "quantserve.com",
        "chartbeat.com",
        "hotjar.com",
        "mixpanel.com",
        "segment.com",
        "segment.io",
        "amplitude.com",
        "branch.io",
        "appsflyer.com",
        "adjust.com",
        "kochava.com",
        "mparticle.com",
        "fullstory.com",
        "mouseflow.com",
        "crazyegg.com",
        "clarity.ms",
        "connect.facebook.net",
    )

    // Third-party social widgets that primarily exist to track browsing
    // across sites the user never actually visits.
    private val socialTrackerDomains = setOf(
        "platform.twitter.com",
        "analytics.twitter.com",
        "ads-twitter.com",
        "pixel.tumblr.com",
        "widgets.pinterest.com",
        "analytics.pinterest.com",
    )

    private val blockedDomains: Set<String> = adDomains + trackerDomains + socialTrackerDomains

    val blockedDomainCount: Int get() = blockedDomains.size

    /**
     * True if [host] is, or is a subdomain of, a known ad/tracker domain,
     * and isn't covered by [allowlist] (a per-site "trust this site"
     * override — domains the user has explicitly allowed).
     */
    fun isBlocked(host: String?, enabled: Boolean, allowlist: Set<String> = emptySet()): Boolean {
        if (!enabled || host.isNullOrBlank()) return false
        val normalizedHost = host.lowercase().removeSuffix(".")
        if (matchesAny(normalizedHost, allowlist)) return false
        return matchesAny(normalizedHost, blockedDomains)
    }

    private fun matchesAny(host: String, domains: Set<String>): Boolean =
        domains.any { host == it || host.endsWith(".$it") }
}
