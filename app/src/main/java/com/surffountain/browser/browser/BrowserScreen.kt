package com.surffountain.browser.browser

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
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
    val context = LocalContext.current
    val privateTabsLabel = stringResource(R.string.menu_new_private_tab)
    val tabGroupsLabel = stringResource(R.string.menu_add_to_group)
    val recentTabsLabel = stringResource(R.string.menu_recent_tabs)

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
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            if (isHome) {
                HomeScreen(
                    totalBlockedCount = totalBlockedCount,
                    onSubmitQuery = { query -> viewModel.submitAddressBarInput(query) },
                    onOpenPdlAi = onNavigateToPdlAi
                )
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
                            setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
                                val (systemId, fileName) = DownloadStarter.enqueue(
                                    context = context,
                                    url = url,
                                    userAgent = userAgent,
                                    contentDisposition = contentDisposition,
                                    mimeType = mimeType
                                )
                                viewModel.recordDownload(systemId, url, fileName, mimeType)
                            }
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

    comingSoonFeature?.let { feature ->
        ComingSoonDialog(featureName = feature, onDismiss = { comingSoonFeature = null })
    }
}

private fun openDefaultAppsSettings(context: Context) {
    val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    runCatching { context.startActivity(intent) }
}
