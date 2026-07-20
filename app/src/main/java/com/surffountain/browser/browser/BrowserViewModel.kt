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
