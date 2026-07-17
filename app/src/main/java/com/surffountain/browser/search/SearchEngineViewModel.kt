package com.surffountain.browser.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SearchEngineViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    val searchTemplate: StateFlow<String> = settingsDataStore.searchTemplate.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.DEFAULT_SEARCH_TEMPLATE
    )

    fun select(engine: SearchEngine) {
        viewModelScope.launch { settingsDataStore.setSearchTemplate(engine.template) }
    }

    fun setCustomTemplate(template: String) {
        if (template.contains("%s")) {
            viewModelScope.launch { settingsDataStore.setSearchTemplate(template) }
        }
    }
}
