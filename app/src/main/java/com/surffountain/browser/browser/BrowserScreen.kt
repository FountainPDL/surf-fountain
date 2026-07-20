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
