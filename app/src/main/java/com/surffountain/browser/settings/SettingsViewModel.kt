package com.surffountain.browser.settings

import android.webkit.CookieManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.data.repository.HistoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore,
    private val historyRepository: HistoryRepository
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

    /** Clears history (Room) and cookies (WebView) — the two pieces of
     *  "browsing data" Surf Fountain actually accumulates today. Cache/
     *  site-storage clearing lands with the Privacy phase's site settings. */
    fun clearBrowsingData() {
        viewModelScope.launch { historyRepository.clearAll() }
        CookieManager.getInstance().removeAllCookies(null)
    }
}
