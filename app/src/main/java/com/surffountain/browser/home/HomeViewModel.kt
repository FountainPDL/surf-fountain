package com.surffountain.browser.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.local.entity.HistoryEntity
import com.surffountain.browser.data.repository.HistoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    historyRepository: HistoryRepository
) : ViewModel() {
    val mostVisited: StateFlow<List<HistoryEntity>> = historyRepository.observeMostVisited(9)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
}
