#!/usr/bin/env bash
# apply-shields-and-adaptive-layout.sh
#
# Surf Fountain — Phase 1a: Shields (ad/tracker blocking) + adaptive
# layout + gesture/button navigation-bar insets.
#
# Run from the root of your surf-fountain repo:
#   bash apply-shields-and-adaptive-layout.sh
#
# Every path below is written relative to the current directory — cd into
# ~/surf-fountain first. This OVERWRITES the listed files with their new
# complete contents (not a diff/patch), and creates the few that are new.

set -euo pipefail
echo "Applying Shields + adaptive layout changes..."

mkdir -p \
  app/src/main/java/com/surffountain/browser/bookmarks \
  app/src/main/java/com/surffountain/browser/browser \
  app/src/main/java/com/surffountain/browser/browser/model \
  app/src/main/java/com/surffountain/browser/browser/webview \
  app/src/main/java/com/surffountain/browser/data/preferences \
  app/src/main/java/com/surffountain/browser/history \
  app/src/main/java/com/surffountain/browser/home \
  app/src/main/java/com/surffountain/browser/privacy \
  app/src/main/java/com/surffountain/browser/settings \
  app/src/main/java/com/surffountain/browser/ui/util \
  app/src/main/res/values \
  app/src/test/java/com/surffountain/browser

echo '  writing app/src/main/java/com/surffountain/browser/privacy/AdBlockEngine.kt'
cat > app/src/main/java/com/surffountain/browser/privacy/AdBlockEngine.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/test/java/com/surffountain/browser/AdBlockEngineTest.kt'
cat > app/src/test/java/com/surffountain/browser/AdBlockEngineTest.kt << 'SFEOF'
package com.surffountain.browser

import com.surffountain.browser.privacy.AdBlockEngine
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AdBlockEngineTest {

    @Test
    fun exactDomainMatchIsBlocked() {
        assertTrue(AdBlockEngine.isBlocked("doubleclick.net", enabled = true))
    }

    @Test
    fun subdomainOfBlockedDomainIsBlocked() {
        assertTrue(AdBlockEngine.isBlocked("ad.doubleclick.net", enabled = true))
    }

    @Test
    fun unrelatedDomainIsNotBlocked() {
        assertFalse(AdBlockEngine.isBlocked("example.com", enabled = true))
    }

    @Test
    fun similarButUnrelatedDomainIsNotFalselyBlocked() {
        // must not match on a substring — "notdoubleclick.net" is not
        // doubleclick.net nor a subdomain of it
        assertFalse(AdBlockEngine.isBlocked("notdoubleclick.net", enabled = true))
    }

    @Test
    fun disabledShieldsBlocksNothing() {
        assertFalse(AdBlockEngine.isBlocked("doubleclick.net", enabled = false))
    }

    @Test
    fun allowlistedDomainIsNotBlocked() {
        assertFalse(
            AdBlockEngine.isBlocked("doubleclick.net", enabled = true, allowlist = setOf("doubleclick.net"))
        )
    }

    @Test
    fun allowlistCoversSubdomainsToo() {
        assertFalse(
            AdBlockEngine.isBlocked("ads.doubleclick.net", enabled = true, allowlist = setOf("doubleclick.net"))
        )
    }

    @Test
    fun blankOrNullHostIsNotBlocked() {
        assertFalse(AdBlockEngine.isBlocked("", enabled = true))
        assertFalse(AdBlockEngine.isBlocked(null, enabled = true))
    }

    @Test
    fun matchingIsCaseInsensitive() {
        assertTrue(AdBlockEngine.isBlocked("Ad.DoubleClick.NET", enabled = true))
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/ShieldsPanel.kt'
cat > app/src/main/java/com/surffountain/browser/browser/ShieldsPanel.kt << 'SFEOF'
package com.surffountain.browser.browser

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.surffountain.browser.R
import com.surffountain.browser.privacy.AdBlockEngine

/**
 * Reachable by tapping the badge in the address bar (see AddressBar.kt's
 * ShieldsBadge). v1: one global on/off switch + this page's block count.
 * Per-site allow-listing is the natural next step — AdBlockEngine.isBlocked
 * already accepts an allowlist parameter, nothing here is a dead end.
 */
@Composable
fun ShieldsPanel(
    siteHost: String,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onToggle: (Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.shields_title)) },
        text = {
            Column {
                if (siteHost.isNotBlank()) {
                    Text(
                        text = siteHost,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
                Text(
                    text = if (blockedCount > 0) {
                        stringResource(R.string.shields_blocked_on_page, blockedCount)
                    } else {
                        stringResource(R.string.shields_nothing_blocked)
                    },
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(stringResource(R.string.shields_toggle_label), style = MaterialTheme.typography.bodyLarge)
                    Switch(checked = shieldsEnabled, onCheckedChange = onToggle)
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = stringResource(R.string.shields_description, AdBlockEngine.blockedDomainCount),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_done)) }
        }
    )
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/util/WindowSizeUtils.kt'
cat > app/src/main/java/com/surffountain/browser/ui/util/WindowSizeUtils.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/AddressBar.kt'
cat > app/src/main/java/com/surffountain/browser/browser/AddressBar.kt << 'SFEOF'
package com.surffountain.browser.browser

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.surffountain.browser.R

@Composable
fun AddressBar(
    displayUrl: String,
    isSecure: Boolean,
    isLoading: Boolean,
    progress: Int,
    isBookmarked: Boolean,
    tabCount: Int,
    canGoBack: Boolean,
    canGoForward: Boolean,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onSubmit: (String) -> Unit,
    onToggleBookmark: () -> Unit,
    onTabsClick: () -> Unit,
    onBack: () -> Unit,
    onForward: () -> Unit,
    onReload: () -> Unit,
    onMenuClick: () -> Unit,
    onShieldsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colorScheme = MaterialTheme.colorScheme

    Column(modifier = modifier) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(start = 4.dp, end = 8.dp)
        ) {
            IconButton(onClick = onBack, enabled = canGoBack) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.action_back),
                    tint = if (canGoBack) colorScheme.onSurface else colorScheme.onSurface.copy(alpha = 0.3f)
                )
            }
            IconButton(onClick = onForward, enabled = canGoForward) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = stringResource(R.string.action_forward),
                    tint = if (canGoForward) colorScheme.onSurface else colorScheme.onSurface.copy(alpha = 0.3f)
                )
            }

            Surface(
                shape = RoundedCornerShape(20.dp),
                color = colorScheme.surfaceVariant,
                modifier = Modifier.weight(1f).height(42.dp)
            ) {
                AddressField(
                    displayUrl = displayUrl,
                    isSecure = isSecure,
                    shieldsEnabled = shieldsEnabled,
                    blockedCount = blockedCount,
                    onSubmit = onSubmit,
                    onShieldsClick = onShieldsClick
                )
            }

            IconButton(onClick = onReload) {
                Icon(
                    Icons.Filled.Refresh,
                    contentDescription = stringResource(R.string.action_reload),
                    tint = colorScheme.onSurface
                )
            }
            IconButton(onClick = onToggleBookmark) {
                Icon(
                    Icons.Filled.Star,
                    contentDescription = stringResource(
                        if (isBookmarked) R.string.action_remove_bookmark else R.string.action_add_bookmark
                    ),
                    tint = if (isBookmarked) colorScheme.primary else colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
            TabCountButtonSimple(count = tabCount, onClick = onTabsClick, tint = colorScheme.onSurface)
            IconButton(onClick = onMenuClick) {
                Icon(Icons.Filled.MoreVert, contentDescription = stringResource(R.string.settings_title), tint = colorScheme.onSurface)
            }
        }

        if (isLoading) {
            LinearProgressIndicator(
                progress = { (progress.coerceIn(0, 100)) / 100f },
                modifier = Modifier.fillMaxWidth().height(2.dp),
                color = colorScheme.primary,
                trackColor = Color.Transparent
            )
        }
    }
}

@Composable
private fun TabCountButtonSimple(count: Int, onClick: () -> Unit, tint: Color) {
    IconButton(onClick = onClick) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(RoundedCornerShape(6.dp))
                .then(Modifier.background(Color.Transparent)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = if (count > 99) "99+" else count.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = tint,
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .padding(horizontal = 2.dp)
            )
        }
    }
}

@Composable
private fun AddressField(
    displayUrl: String,
    isSecure: Boolean,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onSubmit: (String) -> Unit,
    onShieldsClick: () -> Unit
) {
    var text by remember(displayUrl) { mutableStateOf(TextFieldValue(displayUrl)) }
    val colorScheme = MaterialTheme.colorScheme
    val insecureWarning = displayUrl.isNotEmpty() && !isSecure

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)
    ) {
        ShieldsBadge(
            blockedCount = blockedCount,
            enabled = shieldsEnabled,
            onClick = onShieldsClick
        )
        Box(modifier = Modifier.width(8.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (text.text.isEmpty()) {
                Text(
                    text = stringResource(R.string.address_bar_hint),
                    style = MaterialTheme.typography.bodyMedium,
                    color = colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }
            BasicTextField(
                value = text,
                onValueChange = { text = it },
                singleLine = true,
                textStyle = MaterialTheme.typography.bodyMedium.copy(
                    color = if (insecureWarning) colorScheme.error else colorScheme.onSurface
                ),
                cursorBrush = SolidColor(colorScheme.primary),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go, keyboardType = KeyboardType.Uri),
                keyboardActions = KeyboardActions(onGo = {
                    onSubmit(text.text)
                }),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Replaces a generic padlock icon with something actually useful: tap it
 * to see (and toggle) Shields for this site. Shows the blocked-on-this-page
 * count once anything's been blocked, a plain dot before that. Deliberately
 * not a literal shield glyph — that specific icon isn't in the core
 * Material icon set (material-icons-extended only), and a custom badge is
 * closer to how Brave itself does this (a count, not a generic icon) anyway.
 */
@Composable
private fun ShieldsBadge(blockedCount: Int, enabled: Boolean, onClick: () -> Unit) {
    val tint = if (enabled) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    }
    Box(
        modifier = Modifier
            .size(24.dp)
            .clip(CircleShape)
            .background(tint.copy(alpha = 0.15f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (blockedCount > 0) {
            Text(
                text = if (blockedCount > 99) "99+" else blockedCount.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = tint,
                fontSize = 9.sp
            )
        } else {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(tint)
            )
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/model/Tab.kt'
cat > app/src/main/java/com/surffountain/browser/browser/model/Tab.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/webview/WebViewEventListener.kt'
cat > app/src/main/java/com/surffountain/browser/browser/webview/WebViewEventListener.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/webview/SurfFountainWebViewClient.kt'
cat > app/src/main/java/com/surffountain/browser/browser/webview/SurfFountainWebViewClient.kt << 'SFEOF'
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
 */
class SurfFountainWebViewClient(
    private val listener: WebViewEventListener,
    private val isShieldsEnabled: () -> Boolean,
    private val allowlistForCurrentSite: () -> Set<String> = { emptySet() }
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
            "http", "https" -> false
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
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt'
cat > app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt << 'SFEOF'
package com.surffountain.browser.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "surf_fountain_settings")

enum class AppTheme { SYSTEM, LIGHT, DARK }

/**
 * Small, flat key-value settings. FountainSurf (the in-house search
 * provider) needs a live backend and isn't built yet, so the default
 * search/home engine here is a real, working one (DuckDuckGo, in keeping
 * with "Private" being half the app's tagline) rather than a placeholder
 * URL that goes nowhere. The Search phase adds a proper multi-engine
 * picker; this key is where it plugs in.
 */
@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val HOME_PAGE_URL = stringPreferencesKey("home_page_url")
        val SEARCH_TEMPLATE = stringPreferencesKey("search_template")
        val SHIELDS_ENABLED = booleanPreferencesKey("shields_enabled")
    }

    val theme: Flow<AppTheme> = context.dataStore.data.map { prefs ->
        when (prefs[Keys.THEME]) {
            "LIGHT" -> AppTheme.LIGHT
            "DARK" -> AppTheme.DARK
            else -> AppTheme.SYSTEM
        }
    }

    /** What a new tab, and the toolbar Home button, navigate to. Defaults
     *  to the native New-Tab page rather than an external URL — the same
     *  default every mainstream mobile browser ships with. */
    val homePageUrl: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.HOME_PAGE_URL] ?: HOME_SENTINEL
    }

    /** URL template (containing a literal "%s") used to turn a typed or
     *  home-screen search query into a URL. DuckDuckGo by default, in
     *  keeping with "Private" being half the app's tagline; becomes a full
     *  multi-engine picker in the Search phase. */
    val searchTemplate: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.SEARCH_TEMPLATE] ?: DEFAULT_SEARCH_TEMPLATE
    }

    /** Shields — ad/tracker blocking. On by default, in keeping with
     *  "Private" being half the app's tagline. */
    val shieldsEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.SHIELDS_ENABLED] ?: true
    }

    suspend fun setShieldsEnabled(enabled: Boolean) {
        context.dataStore.edit { it[Keys.SHIELDS_ENABLED] = enabled }
    }

    suspend fun setTheme(theme: AppTheme) {
        context.dataStore.edit { it[Keys.THEME] = theme.name }
    }

    suspend fun setHomePageUrl(url: String) {
        context.dataStore.edit { it[Keys.HOME_PAGE_URL] = url }
    }

    suspend fun setSearchTemplate(template: String) {
        context.dataStore.edit { it[Keys.SEARCH_TEMPLATE] = template }
    }

    companion object {
        /** Not a real network scheme — recognized by BrowserScreen to mean
         *  "render the native Home composable instead of a WebView". */
        const val HOME_SENTINEL = "surf://home"
        const val DEFAULT_SEARCH_TEMPLATE = "https://duckduckgo.com/?q=%s"
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/BrowserViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/browser/BrowserViewModel.kt << 'SFEOF'
package com.surffountain.browser.browser

import android.graphics.Bitmap
import android.os.Bundle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.browser.model.Tab
import com.surffountain.browser.browser.webview.WebViewEventListener
import com.surffountain.browser.data.local.entity.TabEntity
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.data.repository.BookmarkRepository
import com.surffountain.browser.data.repository.HistoryRepository
import com.surffountain.browser.data.repository.TabRepository
import com.surffountain.browser.utils.UrlUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class BrowserUiState(
    val tabs: List<Tab> = emptyList(),
    val activeTabId: String? = null,
    val isTabSwitcherVisible: Boolean = false
) {
    val activeTab: Tab? get() = tabs.firstOrNull { it.id == activeTabId }
}

/**
 * Owns tab state and is the single [WebViewEventListener] for whichever tab
 * is currently on-screen. It does NOT own the WebView itself (that's a
 * platform View, created and held by BrowserScreen's AndroidView) — this
 * keeps the ViewModel free of Android View references, which is what
 * actually makes it survive configuration changes cleanly and stay unit
 * testable.
 *
 * Tab-switch protocol the Composable follows:
 *  1. call [captureWebViewState] for the outgoing tab (webView.saveState)
 *  2. call [switchToTab]
 *  3. read the new [BrowserUiState.activeTab] and either
 *     webView.restoreState(tab.webViewState) if present, or
 *     webView.loadUrl(tab.url) for a fresh tab.
 */
@HiltViewModel
class BrowserViewModel @Inject constructor(
    private val tabRepository: TabRepository,
    private val historyRepository: HistoryRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val settingsDataStore: SettingsDataStore
) : ViewModel(), WebViewEventListener {

    private val _tabs = MutableStateFlow<List<Tab>>(emptyList())
    private val _activeTabId = MutableStateFlow<String?>(null)
    private val _isTabSwitcherVisible = MutableStateFlow(false)

    val uiState: StateFlow<BrowserUiState> = combine(
        _tabs, _activeTabId, _isTabSwitcherVisible
    ) { tabs, activeId, switcherVisible ->
        BrowserUiState(tabs, activeId, switcherVisible)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BrowserUiState())

    val isActiveTabBookmarked: StateFlow<Boolean> = combine(_activeTabId, _tabs) { id, tabs ->
        tabs.firstOrNull { it.id == id }?.url
    }.flatMapLatest { url ->
        if (url.isNullOrBlank()) flowOf(false) else bookmarkRepository.observeIsBookmarked(url)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    val searchTemplate: StateFlow<String> = settingsDataStore.searchTemplate.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.DEFAULT_SEARCH_TEMPLATE
    )

    val shieldsEnabled: StateFlow<Boolean> = settingsDataStore.shieldsEnabled.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), true
    )

    fun setShieldsEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsDataStore.setShieldsEnabled(enabled) }
    }

    init {
        viewModelScope.launch {
            val saved = tabRepository.getSavedTabs()
            if (saved.isEmpty()) {
                openNewTab()
            } else {
                val restored = saved.map { entity ->
                    Tab(id = entity.id, url = entity.url, title = entity.title, isPrivate = entity.isPrivate)
                }
                _tabs.value = restored
                _activeTabId.value = restored.first().id
            }
        }
    }

    fun openNewTab(url: String? = null, private: Boolean = false) {
        viewModelScope.launch {
            val targetUrl = url ?: settingsDataStore.homePageUrl.first()
            val tab = Tab(
                id = UUID.randomUUID().toString(),
                url = targetUrl,
                isPrivate = private,
                navigationRequestId = 1
            )
            _tabs.value = _tabs.value + tab
            _activeTabId.value = tab.id
            _isTabSwitcherVisible.value = false
            persistTabs()
        }
    }

    fun closeTab(tabId: String) {
        val remaining = _tabs.value.filterNot { it.id == tabId }
        _tabs.value = remaining
        if (_activeTabId.value == tabId) {
            _activeTabId.value = remaining.lastOrNull()?.id
        }
        viewModelScope.launch {
            tabRepository.deleteTab(tabId)
            if (remaining.isEmpty()) openNewTab()
        }
    }

    fun switchToTab(tabId: String) {
        _activeTabId.value = tabId
        _isTabSwitcherVisible.value = false
    }

    fun showTabSwitcher() {
        _isTabSwitcherVisible.value = true
    }

    fun hideTabSwitcher() {
        _isTabSwitcherVisible.value = false
    }

    /** See the class kdoc for the tab-switch protocol this is step 1 of. */
    fun captureWebViewState(tabId: String, state: Bundle) {
        updateTab(tabId) { it.copy(webViewState = state) }
    }

    fun navigateActiveTabTo(url: String) {
        val id = _activeTabId.value ?: return
        // Dropping the stale saved state + bumping navigationRequestId is
        // what tells BrowserScreen's effect to loadUrl() instead of either
        // restoreState()-ing stale history or silently no-op'ing. Clearing
        // the title specifically for the Home sentinel keeps the tab
        // switcher's "New tab" fallback (Tab.kt / TabSwitcherScreen) from
        // showing the previous page's now-stale title.
        val clearedTitle = url == SettingsDataStore.HOME_SENTINEL
        updateTab(id) {
            it.copy(
                url = url,
                title = if (clearedTitle) "" else it.title,
                webViewState = null,
                navigationRequestId = it.navigationRequestId + 1
            )
        }
    }

    /** Address bar / Home search box entry point: figures out whether
     *  [input] is a URL or a search query and navigates the active tab. */
    fun submitAddressBarInput(input: String) {
        val resolved = UrlUtils.resolveInput(input, searchTemplate.value)
        if (resolved.isNotBlank()) navigateActiveTabTo(resolved)
    }

    fun toggleBookmarkForActiveTab() {
        val tab = uiState.value.activeTab ?: return
        viewModelScope.launch {
            bookmarkRepository.toggleBookmark(
                url = tab.url,
                title = tab.title.ifBlank { tab.url },
                currentlyBookmarked = isActiveTabBookmarked.value
            )
        }
    }

    // ---- WebViewEventListener, driven by the active tab's WebView ---------

    override fun onPageStarted(url: String) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(url = url, isLoading = true, blockedCount = 0) }
    }

    override fun onPageFinished(url: String, title: String?) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(url = url, isLoading = false, title = title ?: it.title) }
        persistTabs()
        val tab = _tabs.value.firstOrNull { it.id == id } ?: return
        if (!tab.isPrivate) {
            viewModelScope.launch {
                historyRepository.recordVisit(tab.url, tab.title.ifBlank { tab.url })
            }
        }
    }

    override fun onProgressChanged(progress: Int) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(progress = progress) }
    }

    override fun onReceivedTitle(title: String) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(title = title) }
    }

    override fun onReceivedIcon(icon: Bitmap?) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(favicon = icon) }
    }

    override fun onRequestBlocked(host: String) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(blockedCount = it.blockedCount + 1) }
    }

    // ---- internal -----------------------------------------------------------

    /**
     * Uses StateFlow's atomic update{} rather than a plain read-modify-write
     * of .value — shouldInterceptRequest can fire from multiple concurrent
     * background-thread calls (a page loading several sub-resources in
     * parallel), and a plain get-then-set here could lose an update under
     * that concurrency. update{} retries under contention instead.
     */
    private fun updateTab(id: String, transform: (Tab) -> Tab) {
        _tabs.update { tabs -> tabs.map { if (it.id == id) transform(it) else it } }
    }

    private fun persistTabs() {
        viewModelScope.launch {
            val entities = _tabs.value.filterNot { it.isPrivate }.mapIndexed { index, tab ->
                TabEntity(
                    id = tab.id,
                    url = tab.url,
                    title = tab.title,
                    position = index,
                    isPrivate = tab.isPrivate
                )
            }
            tabRepository.saveTabs(entities)
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt'
cat > app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt << 'SFEOF'
package com.surffountain.browser.browser

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.ViewGroup
import android.webkit.WebSettings
import android.webkit.WebView
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.browser.webview.SurfFountainWebChromeClient
import com.surffountain.browser.browser.webview.SurfFountainWebViewClient
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.home.HomeScreen

/**
 * Hosts exactly one live WebView for the whole browsing session, reused
 * across every tab (loadUrl for a fresh tab, saveState/restoreState when
 * switching to one that's already been visited) rather than keeping one
 * WebView per tab alive — see BrowserViewModel's kdoc for the full
 * protocol this composable implements.
 */
@SuppressLint("SetJavaScriptEnabled")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowserScreen(
    onNavigateToBookmarks: () -> Unit,
    onNavigateToHistory: () -> Unit,
    onNavigateToSettings: () -> Unit,
    viewModel: BrowserViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val isBookmarked by viewModel.isActiveTabBookmarked.collectAsStateWithLifecycle()
    val shieldsEnabled by viewModel.shieldsEnabled.collectAsStateWithLifecycle()
    val activeTab = uiState.activeTab

    val webViewRef = remember { mutableStateOf<WebView?>(null) }
    var boundTabId by remember { mutableStateOf<String?>(null) }
    var canGoBack by remember { mutableStateOf(false) }
    var canGoForward by remember { mutableStateOf(false) }
    var menuExpanded by remember { mutableStateOf(false) }
    var showShieldsPanel by remember { mutableStateOf(false) }

    val isHome = activeTab == null ||
        activeTab.url == SettingsDataStore.HOME_SENTINEL ||
        activeTab.url.isBlank()

    // System/predictive back: let the page's own history win first: only
    // fall through to "go to New Tab" once the live WebView has nothing
    // left to go back to.
    BackHandler(enabled = !isHome || canGoBack) {
        val wv = webViewRef.value
        if (wv != null && wv.canGoBack()) {
            wv.goBack()
        } else {
            viewModel.navigateActiveTabTo(SettingsDataStore.HOME_SENTINEL)
        }
    }

    // Tab-switch / explicit-navigation driver. Keyed on the active tab's id
    // AND its navigationRequestId (see Tab.kt) so this fires exactly when
    // it should: a real tab switch, a brand new tab, or an explicit
    // navigate-to-this-url call — never on the WebView's own progress/title
    // callbacks updating the same Tab object.
    LaunchedEffect(activeTab?.id, activeTab?.navigationRequestId) {
        val tab = activeTab ?: return@LaunchedEffect
        val wv = webViewRef.value ?: return@LaunchedEffect

        val previousId = boundTabId
        if (previousId != null && previousId != tab.id) {
            val bundle = Bundle()
            wv.saveState(bundle)
            viewModel.captureWebViewState(previousId, bundle)
        }
        boundTabId = tab.id

        when {
            tab.url == SettingsDataStore.HOME_SENTINEL || tab.url.isBlank() -> Unit
            tab.webViewState != null -> wv.restoreState(tab.webViewState)
            else -> wv.loadUrl(tab.url)
        }
    }

    Scaffold(
        bottomBar = {
            // navigationBarsPadding keeps the toolbar clear of both the
            // gesture-nav pill and the classic 3-button bar — whichever the
            // device is actually using, this reads the correct inset for it.
            Box(modifier = Modifier.navigationBarsPadding()) {
                AddressBar(
                    displayUrl = activeTab?.url?.takeUnless {
                        it == SettingsDataStore.HOME_SENTINEL
                    } ?: "",
                    isSecure = activeTab?.url?.startsWith("https://") == true,
                    isLoading = activeTab?.isLoading == true,
                    progress = activeTab?.progress ?: 0,
                    isBookmarked = isBookmarked,
                    tabCount = uiState.tabs.size,
                    canGoBack = canGoBack,
                    canGoForward = canGoForward,
                    shieldsEnabled = shieldsEnabled,
                    blockedCount = activeTab?.blockedCount ?: 0,
                    onSubmit = { input -> viewModel.submitAddressBarInput(input) },
                    onToggleBookmark = viewModel::toggleBookmarkForActiveTab,
                    onTabsClick = viewModel::showTabSwitcher,
                    onBack = { webViewRef.value?.let { if (it.canGoBack()) it.goBack() } },
                    onForward = { webViewRef.value?.let { if (it.canGoForward()) it.goForward() } },
                    onReload = { webViewRef.value?.reload() },
                    onMenuClick = { menuExpanded = true },
                    onShieldsClick = { showShieldsPanel = true }
                )
                DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.tabs_new_tab)) },
                        onClick = { menuExpanded = false; viewModel.openNewTab() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_bookmarks)) },
                        onClick = { menuExpanded = false; onNavigateToBookmarks() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_history)) },
                        onClick = { menuExpanded = false; onNavigateToHistory() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_settings)) },
                        onClick = { menuExpanded = false; onNavigateToSettings() }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            if (isHome) {
                HomeScreen(onSubmitQuery = { query -> viewModel.submitAddressBarInput(query) })
            } else {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { context ->
                        WebView(context).apply {
                            layoutParams = ViewGroup.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            )
                            settings.javaScriptEnabled = true
                            settings.domStorageEnabled = true
                            settings.setSupportZoom(true)
                            settings.builtInZoomControls = true
                            settings.displayZoomControls = false
                            settings.mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
                            webViewClient = SurfFountainWebViewClient(
                                listener = viewModel,
                                isShieldsEnabled = { viewModel.shieldsEnabled.value }
                            )
                            webChromeClient = SurfFountainWebChromeClient(viewModel)
                            webViewRef.value = this
                        }
                    },
                    update = { wv ->
                        canGoBack = wv.canGoBack()
                        canGoForward = wv.canGoForward()
                    }
                )
            }

            if (uiState.isTabSwitcherVisible) {
                TabSwitcherScreen(
                    tabs = uiState.tabs,
                    activeTabId = uiState.activeTabId,
                    onSelectTab = viewModel::switchToTab,
                    onCloseTab = viewModel::closeTab,
                    onNewTab = { viewModel.openNewTab() },
                    onDismiss = viewModel::hideTabSwitcher
                )
            }
        }
    }

    if (showShieldsPanel) {
        val siteHost = activeTab?.url
            ?.takeUnless { it == SettingsDataStore.HOME_SENTINEL }
            ?.let { runCatching { android.net.Uri.parse(it).host }.getOrNull() }
            .orEmpty()
        ShieldsPanel(
            siteHost = siteHost,
            shieldsEnabled = shieldsEnabled,
            blockedCount = activeTab?.blockedCount ?: 0,
            onToggle = viewModel::setShieldsEnabled,
            onDismiss = { showShieldsPanel = false }
        )
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/settings/SettingsViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/settings/SettingsViewModel.kt << 'SFEOF'
package com.surffountain.browser.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {
    val theme: StateFlow<AppTheme> = settingsDataStore.theme
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AppTheme.SYSTEM)

    val homePageUrl: StateFlow<String> = settingsDataStore.homePageUrl
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.HOME_SENTINEL)

    val shieldsEnabled: StateFlow<Boolean> = settingsDataStore.shieldsEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    fun setShieldsEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsDataStore.setShieldsEnabled(enabled) }
    }

    fun setTheme(theme: AppTheme) {
        viewModelScope.launch { settingsDataStore.setTheme(theme) }
    }

    fun setHomePageUrl(url: String) {
        viewModelScope.launch { settingsDataStore.setHomePageUrl(url) }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/settings/SettingsScreen.kt'
cat > app/src/main/java/com/surffountain/browser/settings/SettingsScreen.kt << 'SFEOF'
package com.surffountain.browser.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.BuildConfig
import com.surffountain.browser.R
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val theme by viewModel.theme.collectAsStateWithLifecycle()
    val homePageUrl by viewModel.homePageUrl.collectAsStateWithLifecycle()
    val shieldsEnabled by viewModel.shieldsEnabled.collectAsStateWithLifecycle()
    var homePageText by remember(homePageUrl) {
        mutableStateOf(if (homePageUrl == SettingsDataStore.HOME_SENTINEL) "" else homePageUrl)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
        ) {
            Spacer(Modifier.height(8.dp))
            SectionHeader(stringResource(R.string.settings_appearance))
            Text(
                stringResource(R.string.settings_theme),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
            Column(Modifier.selectableGroup()) {
                ThemeOption(AppTheme.SYSTEM, stringResource(R.string.settings_theme_system), theme, viewModel::setTheme)
                ThemeOption(AppTheme.LIGHT, stringResource(R.string.settings_theme_light), theme, viewModel::setTheme)
                ThemeOption(AppTheme.DARK, stringResource(R.string.settings_theme_dark), theme, viewModel::setTheme)
            }

            Spacer(Modifier.height(24.dp))
            SectionHeader(stringResource(R.string.settings_privacy))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(stringResource(R.string.shields_toggle_label), style = MaterialTheme.typography.bodyLarge)
                    Text(
                        stringResource(R.string.settings_shields_summary),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(checked = shieldsEnabled, onCheckedChange = viewModel::setShieldsEnabled)
            }

            Spacer(Modifier.height(24.dp))
            SectionHeader(stringResource(R.string.settings_general))
            Text(
                stringResource(R.string.settings_home_page),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
            OutlinedTextField(
                value = homePageText,
                onValueChange = { homePageText = it },
                placeholder = { Text("New Tab page") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                trailingIcon = {
                    TextButton(onClick = {
                        viewModel.setHomePageUrl(homePageText.ifBlank { SettingsDataStore.HOME_SENTINEL })
                    }) { Text(stringResource(R.string.action_confirm)) }
                }
            )

            Spacer(Modifier.height(24.dp))
            SectionHeader(stringResource(R.string.settings_about))
            Text(
                text = stringResource(R.string.settings_version, BuildConfig.VERSION_NAME),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp)
            )
            Text(
                text = stringResource(R.string.tagline),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(32.dp))
        }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
}

@Composable
private fun ThemeOption(value: AppTheme, label: String, selected: AppTheme, onSelect: (AppTheme) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = (selected == value), onClick = { onSelect(value) }, role = Role.RadioButton)
            .padding(vertical = 8.dp)
    ) {
        RadioButton(selected = (selected == value), onClick = null)
        Spacer(Modifier.width(12.dp))
        Text(label, style = MaterialTheme.typography.bodyLarge)
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/bookmarks/BookmarksScreen.kt'
cat > app/src/main/java/com/surffountain/browser/bookmarks/BookmarksScreen.kt << 'SFEOF'
package com.surffountain.browser.bookmarks

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    viewModel: BookmarksViewModel = hiltViewModel()
) {
    val bookmarks by viewModel.bookmarks.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.bookmarks_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        if (bookmarks.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(stringResource(R.string.bookmarks_empty), style = MaterialTheme.typography.titleMedium)
                    Text(
                        stringResource(R.string.bookmarks_empty_hint),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(bookmarks, key = { it.id }) { bookmark ->
                    ListItem(
                        headlineContent = {
                            Text(bookmark.title.ifBlank { bookmark.url }, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        supportingContent = {
                            Text(bookmark.url, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        trailingContent = {
                            IconButton(onClick = { viewModel.delete(bookmark) }) {
                                Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.bookmarks_delete))
                            }
                        },
                        modifier = Modifier.clickable { onOpenUrl(bookmark.url) }
                    )
                    HorizontalDivider(modifier = Modifier.height(0.5.dp))
                }
            }
        }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/history/HistoryScreen.kt'
cat > app/src/main/java/com/surffountain/browser/history/HistoryScreen.kt << 'SFEOF'
package com.surffountain.browser.history

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    viewModel: HistoryViewModel = hiltViewModel()
) {
    val history by viewModel.history.collectAsStateWithLifecycle()
    var showClearConfirm by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.history_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                },
                actions = {
                    if (history.isNotEmpty()) {
                        IconButton(onClick = { showClearConfirm = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.history_clear_all))
                        }
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        if (history.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.history_empty), style = MaterialTheme.typography.titleMedium)
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(history, key = { it.id }) { entry ->
                    ListItem(
                        headlineContent = {
                            Text(entry.title.ifBlank { entry.url }, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        supportingContent = {
                            Text(entry.url, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        trailingContent = {
                            IconButton(onClick = { viewModel.delete(entry.id) }) {
                                Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.history_delete_item))
                            }
                        },
                        modifier = Modifier.clickable { onOpenUrl(entry.url) }
                    )
                    HorizontalDivider()
                }
            }
        }
        }
    }

    if (showClearConfirm) {
        AlertDialog(
            onDismissRequest = { showClearConfirm = false },
            title = { Text(stringResource(R.string.history_clear_confirm_title)) },
            text = { Text(stringResource(R.string.history_clear_confirm_body)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearAll()
                    showClearConfirm = false
                }) { Text(stringResource(R.string.action_delete)) }
            },
            dismissButton = {
                TextButton(onClick = { showClearConfirm = false }) { Text(stringResource(R.string.action_cancel)) }
            }
        )
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/home/HomeScreen.kt'
cat > app/src/main/java/com/surffountain/browser/home/HomeScreen.kt << 'SFEOF'
package com.surffountain.browser.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.ui.util.AdaptiveContentWidth

/**
 * The native New-Tab page — rendered by BrowserScreen whenever the active
 * tab's url is SettingsDataStore.HOME_SENTINEL, the same way Chrome/Firefox
 * show a native page rather than actually navigating anywhere for a blank
 * new tab. News cards / weather / wallpaper customization from the full
 * spec are follow-up phases; this is the functional core (search + most
 * visited) done for real rather than stubbed out.
 */
@Composable
fun HomeScreen(
    onSubmitQuery: (String) -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val mostVisited by viewModel.mostVisited.collectAsStateWithLifecycle()
    var query by remember { mutableStateOf("") }

    AdaptiveContentWidth(modifier = Modifier.fillMaxSize()) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(56.dp))
        Text(
            text = stringResource(R.string.app_name),
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(20.dp))

        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.fillMaxWidth().height(48.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)
            ) {
                Icon(Icons.Filled.Search, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(modifier = Modifier.width(10.dp))
                Box(modifier = Modifier.weight(1f)) {
                    if (query.isEmpty()) {
                        Text(
                            text = stringResource(R.string.address_bar_hint),
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                    BasicTextField(
                        value = query,
                        onValueChange = { query = it },
                        singleLine = true,
                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = MaterialTheme.colorScheme.onSurface),
                        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { onSubmitQuery(query) }),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        if (mostVisited.isNotEmpty()) {
            Text(
                text = stringResource(R.string.home_most_visited),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(mostVisited, key = { it.url }) { entry ->
                    MostVisitedTile(title = entry.title.ifBlank { entry.url }, onClick = { onSubmitQuery(entry.url) })
                }
            }
        } else {
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = stringResource(R.string.home_no_history_yet),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
    }
}

@Composable
private fun MostVisitedTile(title: String, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        modifier = Modifier.fillMaxWidth().height(64.dp)
    ) {
        Box(modifier = Modifier.padding(8.dp).fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
        }
    }
}
SFEOF

echo '  writing app/src/main/res/values/strings.xml'
cat > app/src/main/res/values/strings.xml << 'SFEOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Surf Fountain</string>
    <string name="tagline">Fast. Private. Powerful.</string>

    <!-- Address bar -->
    <string name="address_bar_hint">Search or enter address</string>
    <string name="action_go">Go</string>
    <string name="action_reload">Reload</string>
    <string name="action_stop">Stop</string>
    <string name="action_back">Back</string>
    <string name="action_forward">Forward</string>
    <string name="action_share">Share</string>
    <string name="action_add_bookmark">Add bookmark</string>
    <string name="action_remove_bookmark">Remove bookmark</string>

    <!-- Tabs -->
    <string name="tabs_new_tab">New tab</string>
    <string name="tabs_close_tab">Close tab</string>
    <string name="tabs_switcher_title">%1$d tabs</string>
    <string name="tabs_empty">No open tabs</string>

    <!-- Home -->
    <string name="home_most_visited">Most visited</string>
    <string name="home_no_history_yet">Sites you visit will show up here</string>

    <!-- Bookmarks -->
    <string name="bookmarks_title">Bookmarks</string>
    <string name="bookmarks_empty">No bookmarks yet</string>
    <string name="bookmarks_empty_hint">Tap the star in the address bar to save a page</string>
    <string name="bookmarks_delete">Delete bookmark</string>

    <!-- History -->
    <string name="history_title">History</string>
    <string name="history_empty">No browsing history yet</string>
    <string name="history_clear_all">Clear all history</string>
    <string name="history_clear_confirm_title">Clear history?</string>
    <string name="history_clear_confirm_body">This removes every site you\'ve visited from this device. This can\'t be undone.</string>
    <string name="history_delete_item">Remove from history</string>

    <!-- Settings -->
    <string name="settings_title">Settings</string>
    <string name="settings_appearance">Appearance</string>
    <string name="settings_theme">Theme</string>
    <string name="settings_theme_system">Match system</string>
    <string name="settings_theme_light">Light</string>
    <string name="settings_theme_dark">Dark</string>
    <string name="settings_privacy">Privacy</string>
    <string name="settings_shields_summary">Block known ad and tracker domains automatically</string>
    <string name="settings_general">General</string>
    <string name="settings_home_page">Home page</string>
    <string name="settings_about">About Surf Fountain</string>
    <string name="settings_version">Version %1$s</string>

    <!-- Navigation labels -->
    <string name="nav_home">Home</string>
    <string name="nav_tabs">Tabs</string>
    <string name="nav_bookmarks">Bookmarks</string>
    <string name="nav_history">History</string>
    <string name="nav_settings">Settings</string>

    <!-- Shields -->
    <string name="shields_title">Shields</string>
    <string name="shields_blocked_on_page">%1$d trackers and ads blocked on this page</string>
    <string name="shields_nothing_blocked">Nothing blocked on this page yet</string>
    <string name="shields_toggle_label">Shields</string>
    <string name="shields_description">Blocking %1$d known ad/tracker domains. Applies everywhere for now — per-site control is next.</string>

    <!-- Common -->
    <string name="action_cancel">Cancel</string>
    <string name="action_confirm">Confirm</string>
    <string name="action_delete">Delete</string>
    <string name="action_close">Close</string>
    <string name="action_done">Done</string>
</resources>
SFEOF

echo
echo "Done. 17 files written (4 new, 13 updated)."
echo "Next: git add -A && git commit -m \"Shields + adaptive layout\" && git push, then bash scripts/build.sh"
