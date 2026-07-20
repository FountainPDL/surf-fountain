#!/usr/bin/env bash
# fix-navigation-and-downloads.sh
#
# Fixes this round:
#   - back/forward buttons, tab 'bleed' between tabs — root cause was the
#     WebView getting disposed + recreated every time you opened a new tab or
#     hit Home; it's now a single WebView that stays mounted for the whole
#     browsing session, with Home drawn as an overlay on top of it instead
#   - Home button added to the toolbar (Reload moved inside the address field
#     to make room, so the button count stays the same)
#   - address bar now expands to show what you're typing (TextFieldValue fix)
#   - browser always opens on a fresh New Tab page on launch
#   - Full Screen added to the menu, hides the toolbar until you press back
#   - Google is now the default search engine, AND the actual bug: search
#     engine selection wasn't persisting because the DataStore write could get
#     cancelled mid-flight if you navigated away right after picking one —
#     writes are now wrapped in NonCancellable so they always finish
#   - downloads: a link to a .pdf/.zip/.apk/etc. is now intercepted BEFORE the
#     WebView tries to navigate to it (that attempt was the black screen +
#     reload loop); dynamic download URLs still work via the existing
#     DownloadListener fallback, now with stopLoading() so they can't leave
#     the WebView stuck either
#   - history recorded 3-5x per page — onPageFinished genuinely fires more
#     than once per page load (once per iframe, plus redirects settling);
#     now only records when the URL actually changed since the last entry
#
# Run from the root of your surf-fountain repo: bash fix-navigation-and-downloads.sh

set -euo pipefail
echo "Applying navigation, download, search engine, and history fixes..."

mkdir -p \
  app/src/main/java/com/surffountain/browser/browser \
  app/src/main/java/com/surffountain/browser/browser/webview \
  app/src/main/java/com/surffountain/browser/data/preferences \
  app/src/main/res/values

echo '  writing app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt'
cat > app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt << 'SFEOF'
package com.surffountain.browser.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "surf_fountain_settings")

enum class AppTheme { SYSTEM, LIGHT, DARK }

/**
 * Small, flat key-value settings. FountainSurf (the in-house search
 * provider) needs a live backend and isn't built yet, so the default
 * search/home engine here is a real, working one rather than a
 * placeholder URL that goes nowhere. The Search phase adds a proper
 * multi-engine picker; this key is where it plugs in.
 *
 * Every write goes through withContext(NonCancellable): these are all
 * launched from viewModelScope.launch { ... } call sites, and a
 * ViewModel's scope gets cancelled the moment its screen is popped —
 * which happens easily and fast (pick a setting, immediately tap back).
 * Without NonCancellable, a write racing that cancellation silently never
 * reaches disk. That was the actual cause of "search engine choice doesn't
 * take effect" — not a logic bug in the read/write itself.
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
        val TOTAL_BLOCKED_COUNT = longPreferencesKey("total_blocked_count")
        val PDL_AI_API_KEY = stringPreferencesKey("pdl_ai_api_key")
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
     *  home-screen search query into a URL. Google by default; becomes a
     *  full multi-engine picker in Settings > Search engine. */
    val searchTemplate: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.SEARCH_TEMPLATE] ?: DEFAULT_SEARCH_TEMPLATE
    }

    /** Shields — ad/tracker blocking. On by default, in keeping with
     *  "Private" being half the app's tagline. */
    val shieldsEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.SHIELDS_ENABLED] ?: true
    }

    suspend fun setShieldsEnabled(enabled: Boolean) = writeNonCancellable {
        context.dataStore.edit { it[Keys.SHIELDS_ENABLED] = enabled }
    }

    /** All-time blocked count, for the New Tab Privacy Stats widget.
     *  BrowserViewModel flushes each page's live count in here as that
     *  page is navigated away from or its tab closes — see its kdoc. */
    val totalBlockedCount: Flow<Long> = context.dataStore.data.map { prefs ->
        prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
    }

    suspend fun addToBlockedCount(delta: Long) {
        if (delta <= 0) return
        writeNonCancellable {
            context.dataStore.edit { prefs ->
                val current = prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
                prefs[Keys.TOTAL_BLOCKED_COUNT] = current + delta
            }
        }
    }

    /** Stored in plain DataStore for now, not Android Keystore-encrypted —
     *  fine for local development, not where this should stay once PDL AI
     *  actually makes calls with it. Flagged here on purpose rather than
     *  quietly left as a surprise. */
    val pdlAiApiKey: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.PDL_AI_API_KEY] ?: ""
    }

    suspend fun setPdlAiApiKey(key: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.PDL_AI_API_KEY] = key }
    }

    suspend fun setTheme(theme: AppTheme) = writeNonCancellable {
        context.dataStore.edit { it[Keys.THEME] = theme.name }
    }

    suspend fun setHomePageUrl(url: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.HOME_PAGE_URL] = url }
    }

    suspend fun setSearchTemplate(template: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.SEARCH_TEMPLATE] = template }
    }

    private suspend fun writeNonCancellable(block: suspend () -> Unit) {
        withContext(NonCancellable) { block() }
    }

    companion object {
        /** Not a real network scheme — recognized by BrowserScreen to mean
         *  "render the native Home composable instead of a WebView". */
        const val HOME_SENTINEL = "surf://home"
        const val DEFAULT_SEARCH_TEMPLATE = "https://www.google.com/search?q=%s"
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
import com.surffountain.browser.data.repository.DownloadRepository
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
    private val downloadRepository: DownloadRepository,
    private val settingsDataStore: SettingsDataStore
) : ViewModel(), WebViewEventListener {

    private val _tabs = MutableStateFlow<List<Tab>>(emptyList())
    private val _activeTabId = MutableStateFlow<String?>(null)
    private val _isTabSwitcherVisible = MutableStateFlow(false)
    private val lastRecordedHistoryUrl = mutableMapOf<String, String>()

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

    fun recordDownload(systemDownloadId: Long, url: String, fileName: String, mimeType: String?) {
        viewModelScope.launch {
            downloadRepository.recordNewDownload(systemDownloadId, url, fileName, mimeType)
        }
    }

    /** Persisted all-time total, plus whatever the active tab has blocked
     *  on its current page (not yet flushed — see flushBlockedCountToTotal).
     *  Background tabs never contribute here since only the active tab's
     *  WebView is live and calling onRequestBlocked. */
    val totalBlockedCount: StateFlow<Long> = combine(
        settingsDataStore.totalBlockedCount,
        _activeTabId,
        _tabs
    ) { persisted, activeId, tabs ->
        persisted + (tabs.firstOrNull { it.id == activeId }?.blockedCount ?: 0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L)

    init {
        viewModelScope.launch {
            val saved = tabRepository.getSavedTabs()
            if (saved.isNotEmpty()) {
                val restored = saved.map { entity ->
                    Tab(id = entity.id, url = entity.url, title = entity.title, isPrivate = entity.isPrivate)
                }
                _tabs.value = restored
            }
            // Always open fresh on the New Tab page on cold start, regardless
            // of what got restored above — those restored tabs are still
            // there in the tab switcher, just not what's shown first. A
            // "resume where I left off" Settings toggle is a follow-up.
            openNewTab()
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
        flushBlockedCountToTotal(tabId)
        lastRecordedHistoryUrl.remove(tabId)
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
        flushBlockedCountToTotal(id)
        updateTab(id) { it.copy(url = url, isLoading = true, blockedCount = 0) }
    }

    override fun onPageFinished(url: String, title: String?) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(url = url, isLoading = false, title = title ?: it.title) }
        persistTabs()
        val tab = _tabs.value.firstOrNull { it.id == id } ?: return
        // WebViewClient.onPageFinished genuinely fires more than once for a
        // single page a human would call "one visit" — once per iframe, and
        // again as redirects settle. Without this guard each of those wrote
        // a separate History row, which is exactly the "recorded 3-5 times"
        // bug. One recorded entry per genuine URL change, per tab.
        if (!tab.isPrivate && lastRecordedHistoryUrl[id] != url) {
            lastRecordedHistoryUrl[id] = url
            viewModelScope.launch {
                historyRepository.recordVisit(tab.url, tab.title.ifBlank { tab.url })
            }
        }
    }

    /** Called when a download is detected instead of a real page (see
     *  SurfFountainWebViewClient / BrowserScreen's DownloadListener) — the
     *  page never actually finished loading as a page, so isLoading would
     *  otherwise be stuck true forever with nothing to show for it. */
    fun onDownloadDetected() {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(isLoading = false) }
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

    private fun flushBlockedCountToTotal(tabId: String) {
        val count = _tabs.value.firstOrNull { it.id == tabId }?.blockedCount ?: 0
        if (count > 0) {
            viewModelScope.launch { settingsDataStore.addToBlockedCount(count.toLong()) }
        }
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
import androidx.compose.material.icons.filled.Home
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
    onHome: () -> Unit,
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
            IconButton(onClick = onHome) {
                Icon(
                    Icons.Filled.Home,
                    contentDescription = stringResource(R.string.nav_home),
                    tint = colorScheme.onSurface
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
                    onShieldsClick = onShieldsClick,
                    onReload = onReload
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
    onShieldsClick: () -> Unit,
    onReload: () -> Unit
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
        IconButton(onClick = onReload, modifier = Modifier.size(32.dp)) {
            Icon(
                Icons.Filled.Refresh,
                contentDescription = stringResource(R.string.action_reload),
                tint = colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp)
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

echo '  writing app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt'
cat > app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt << 'SFEOF'
package com.surffountain.browser.browser

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.browser.webview.SurfFountainWebChromeClient
import com.surffountain.browser.browser.webview.SurfFountainWebViewClient
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.downloads.DownloadStarter
import com.surffountain.browser.home.HomeScreen
import com.surffountain.browser.ui.components.ComingSoonDialog
import com.surffountain.browser.ui.components.SoonBadge

/**
 * Hosts exactly one live WebView for the whole browsing session, and it
 * stays mounted for BrowserScreen's entire lifetime — Home is drawn as an
 * opaque overlay ON TOP of it when the active tab is on
 * SettingsDataStore.HOME_SENTINEL, not swapped in by removing the WebView
 * from composition. An earlier version did the latter (if/else between
 * HomeScreen and AndroidView), which disposed and recreated the WebView
 * every time the user opened a new tab or hit Home — that's what was
 * actually behind back/forward "not working" (a fresh WebView has no
 * history) and tabs appearing to bleed into each other. One WebView,
 * created once, for as long as this screen exists, is the fix.
 */
@SuppressLint("SetJavaScriptEnabled")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowserScreen(
    onNavigateToBookmarks: () -> Unit,
    onNavigateToHistory: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToPdlAi: () -> Unit,
    onNavigateToDownloads: () -> Unit,
    viewModel: BrowserViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val isBookmarked by viewModel.isActiveTabBookmarked.collectAsStateWithLifecycle()
    val shieldsEnabled by viewModel.shieldsEnabled.collectAsStateWithLifecycle()
    val totalBlockedCount by viewModel.totalBlockedCount.collectAsStateWithLifecycle()
    val activeTab = uiState.activeTab

    val webViewRef = remember { mutableStateOf<WebView?>(null) }
    var boundTabId by remember { mutableStateOf<String?>(null) }
    var canGoBack by remember { mutableStateOf(false) }
    var canGoForward by remember { mutableStateOf(false) }
    var menuExpanded by remember { mutableStateOf(false) }
    var showShieldsPanel by remember { mutableStateOf(false) }
    var comingSoonFeature by remember { mutableStateOf<String?>(null) }
    var isFullscreen by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val privateTabsLabel = stringResource(R.string.menu_new_private_tab)
    val tabGroupsLabel = stringResource(R.string.menu_add_to_group)
    val recentTabsLabel = stringResource(R.string.menu_recent_tabs)

    val isHome = activeTab == null ||
        activeTab.url == SettingsDataStore.HOME_SENTINEL ||
        activeTab.url.isBlank()

    // Fullscreen consumes the first back-press (there's no toolbar visible
    // to tap an exit button on, so this is the expected way out). Otherwise
    // the page's own history wins, falling through to "go to New Tab" once
    // the WebView has nothing left to go back to.
    BackHandler(enabled = isFullscreen || !isHome || canGoBack) {
        when {
            isFullscreen -> isFullscreen = false
            webViewRef.value?.canGoBack() == true -> webViewRef.value?.goBack()
            else -> viewModel.navigateActiveTabTo(SettingsDataStore.HOME_SENTINEL)
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
            if (!isFullscreen) {
                // navigationBarsPadding keeps the toolbar clear of both the
                // gesture-nav pill and the classic 3-button bar.
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
                        onHome = { viewModel.navigateActiveTabTo(SettingsDataStore.HOME_SENTINEL) },
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
                            text = { Text(stringResource(R.string.menu_new_private_tab)) },
                            trailingIcon = { SoonBadge() },
                            onClick = { menuExpanded = false; comingSoonFeature = privateTabsLabel }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.menu_add_to_group)) },
                            trailingIcon = { SoonBadge() },
                            onClick = { menuExpanded = false; comingSoonFeature = tabGroupsLabel }
                        )
                        HorizontalDivider()
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.nav_history)) },
                            onClick = { menuExpanded = false; onNavigateToHistory() }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.downloads_title)) },
                            onClick = { menuExpanded = false; onNavigateToDownloads() }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.nav_bookmarks)) },
                            onClick = { menuExpanded = false; onNavigateToBookmarks() }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.pdl_ai_title)) },
                            onClick = { menuExpanded = false; onNavigateToPdlAi() }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.menu_recent_tabs)) },
                            trailingIcon = { SoonBadge() },
                            onClick = { menuExpanded = false; comingSoonFeature = recentTabsLabel }
                        )
                        HorizontalDivider()
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.menu_full_screen)) },
                            onClick = { menuExpanded = false; isFullscreen = true }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.nav_settings)) },
                            onClick = { menuExpanded = false; onNavigateToSettings() }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.menu_set_as_default)) },
                            onClick = {
                                menuExpanded = false
                                openDefaultAppsSettings(context)
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = { factoryContext ->
                    WebView(factoryContext).also { webView ->
                        webView.layoutParams = ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )
                        webView.settings.javaScriptEnabled = true
                        webView.settings.domStorageEnabled = true
                        webView.settings.setSupportZoom(true)
                        webView.settings.builtInZoomControls = true
                        webView.settings.displayZoomControls = false
                        webView.settings.mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
                        webView.webViewClient = SurfFountainWebViewClient(
                            listener = viewModel,
                            isShieldsEnabled = { viewModel.shieldsEnabled.value },
                            onDownloadUrl = { url ->
                                handleDownload(
                                    context = factoryContext,
                                    webView = webView,
                                    url = url,
                                    userAgent = webView.settings.userAgentString,
                                    contentDisposition = null,
                                    mimeType = null,
                                    viewModel = viewModel
                                )
                            }
                        )
                        webView.webChromeClient = SurfFountainWebChromeClient(viewModel)
                        webView.setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
                            handleDownload(
                                context = factoryContext,
                                webView = webView,
                                url = url,
                                userAgent = userAgent,
                                contentDisposition = contentDisposition,
                                mimeType = mimeType,
                                viewModel = viewModel
                            )
                        }
                        webViewRef.value = webView
                    }
                },
                update = { wv ->
                    canGoBack = wv.canGoBack()
                    canGoForward = wv.canGoForward()
                }
            )

            if (isHome) {
                HomeScreen(
                    totalBlockedCount = totalBlockedCount,
                    onSubmitQuery = { query -> viewModel.submitAddressBarInput(query) },
                    onOpenPdlAi = onNavigateToPdlAi
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

    comingSoonFeature?.let { feature ->
        ComingSoonDialog(featureName = feature, onDismiss = { comingSoonFeature = null })
    }
}

/**
 * Common path for both download-detection routes (proactive extension
 * sniffing in shouldOverrideUrlLoading, and the setDownloadListener
 * fallback for extensionless URLs). stopLoading() is the fix for the
 * black-screen/reload-loop bug: without it, the WebView is left partway
 * through navigating to a URL that was never actually a page — either
 * showing nothing or, depending on the site, retrying indefinitely.
 */
private fun handleDownload(
    context: Context,
    webView: WebView,
    url: String,
    userAgent: String?,
    contentDisposition: String?,
    mimeType: String?,
    viewModel: BrowserViewModel
) {
    webView.stopLoading()
    viewModel.onDownloadDetected()
    val (systemId, fileName) = DownloadStarter.enqueue(
        context = context,
        url = url,
        userAgent = userAgent,
        contentDisposition = contentDisposition,
        mimeType = mimeType
    )
    viewModel.recordDownload(systemId, url, fileName, mimeType)
}

private fun openDefaultAppsSettings(context: Context) {
    val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    runCatching { context.startActivity(intent) }
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
    <string name="menu_new_private_tab">New Private Tab</string>
    <string name="menu_add_to_group">Add tab to group</string>
    <string name="menu_recent_tabs">Recent tabs</string>
    <string name="menu_set_as_default">Set as Default Browser</string>
    <string name="menu_full_screen">Full Screen</string>

    <!-- Home -->
    <string name="home_most_visited">Shortcuts</string>
    <string name="home_no_history_yet">Sites you visit will show up here</string>
    <string name="privacy_stats_label">Trackers &amp; ads blocked</string>
    <string name="pdl_ai_teaser_title">Meet PDL AI</string>
    <string name="pdl_ai_teaser_body">Your assistant, built into the browser. Summarize pages, ask questions, get things written — privately.</string>
    <string name="pdl_ai_get_started">Get started</string>

    <!-- Bookmarks -->
    <string name="bookmarks_title">Bookmarks</string>
    <string name="bookmarks_empty">No bookmarks yet</string>
    <string name="bookmarks_empty_hint">Tap the star in the address bar to save a page</string>
    <string name="bookmarks_delete">Delete bookmark</string>
    <string name="bookmarks_add_note">Add note</string>
    <string name="bookmarks_edit_note">Edit note</string>
    <string name="bookmarks_note_title">Private note</string>
    <string name="bookmarks_note_hint">Visible only to you, never synced anywhere yet</string>

    <!-- History -->
    <string name="history_title">History</string>
    <string name="history_empty">No browsing history yet</string>
    <string name="history_clear_all">Clear all history</string>
    <string name="history_clear_confirm_title">Clear history?</string>
    <string name="history_clear_confirm_body">This removes every site you\'ve visited from this device. This can\'t be undone.</string>
    <string name="history_delete_item">Remove from history</string>

    <!-- Downloads -->
    <string name="downloads_title">Downloads</string>
    <string name="downloads_empty">No downloads yet</string>

    <!-- Settings -->
    <string name="settings_title">Settings</string>
    <string name="settings_section_features">Features</string>
    <string name="settings_appearance">Appearance</string>
    <string name="settings_theme">Theme</string>
    <string name="settings_theme_system">Match system</string>
    <string name="settings_theme_light">Light</string>
    <string name="settings_theme_dark">Dark</string>
    <string name="settings_privacy">Privacy</string>
    <string name="settings_shields_summary">Block known ad and tracker domains automatically</string>
    <string name="settings_pdl_ai_summary">Your assistant, built into the browser</string>
    <string name="settings_news">News</string>
    <string name="settings_vpn">Firewall + VPN</string>
    <string name="settings_general">General</string>
    <string name="settings_search_engine">Search engine</string>
    <string name="settings_custom_search_engine">Custom search engine</string>
    <string name="settings_custom_search_engine_hint">Must contain %s where the query goes</string>
    <string name="settings_home_page">Home page</string>
    <string name="settings_sync">Sync</string>
    <string name="settings_notifications">Notifications</string>
    <string name="settings_site_settings">Site settings</string>
    <string name="settings_clear_data">Clear browsing data</string>
    <string name="settings_clear_data_summary">History and cookies</string>
    <string name="settings_clear_data_confirm_body">This clears your history and cookies from this device. This can\'t be undone.</string>
    <string name="settings_display">Display</string>
    <string name="settings_tabs_groups">Tabs and tab groups</string>
    <string name="settings_new_tab_page">New Tab page</string>
    <string name="settings_accessibility">Accessibility</string>
    <string name="settings_passwords_autofill">Passwords and Autofill</string>
    <string name="settings_password_manager">Password manager</string>
    <string name="settings_autofill">Autofill services</string>
    <string name="settings_exclusive">Surf Fountain exclusive</string>
    <string name="settings_site_notes">Site Notes</string>
    <string name="settings_site_notes_summary">Private notes on any bookmarked page</string>
    <string name="settings_content_downloader">Content Downloader</string>
    <string name="settings_privacy_digest">Privacy Digest</string>
    <string name="settings_privacy_digest_summary">Your blocking history over time</string>
    <string name="settings_support">Support</string>
    <string name="settings_send_feedback">Send feedback</string>
    <string name="settings_about_section">About</string>
    <string name="settings_about">About Surf Fountain</string>
    <string name="settings_version">Version %1$s</string>
    <string name="about_made_by">Made by FountainPDL Ministry</string>
    <string name="about_view_source">View source on GitHub</string>
    <string name="about_open_source_notice">Built entirely from a phone — Termux, GitHub, and GitHub Actions, no desktop involved.</string>

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
    <string name="action_send">Send</string>

    <!-- PDL AI -->
    <string name="pdl_ai_title">PDL AI</string>
    <string name="pdl_ai_empty_title">Ask PDL AI anything</string>
    <string name="pdl_ai_empty_body">The chat works right now — the model connection is the part still being built. See what you get today.</string>
    <string name="pdl_ai_input_hint">Message PDL AI</string>
    <string name="pdl_ai_typing">PDL AI is typing…</string>
    <string name="settings_pdl_ai">PDL AI</string>
    <string name="pdl_ai_api_key_label">API key</string>
    <string name="pdl_ai_api_key_hint">Not connected to a model yet — this is where a key will go</string>

    <!-- Feature stubs -->
    <string name="soon_badge">SOON</string>
    <string name="coming_soon_body">Not built yet — this is a placeholder so the app already looks and navigates like the finished thing. Check docs/ROADMAP.md for what\'s next.</string>
</resources>
SFEOF

echo
echo "Done. 6 files written."
