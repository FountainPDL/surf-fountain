package com.surffountain.browser.downloads

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.repository.DownloadRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DownloadsViewModel @Inject constructor(
    private val downloadRepository: DownloadRepository
) : ViewModel() {

    val downloads: StateFlow<List<DownloadEntity>> = downloadRepository.observeDownloads()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun delete(id: Long) {
        viewModelScope.launch { downloadRepository.delete(id) }
    }

    fun clearAll() {
        viewModelScope.launch { downloadRepository.clearAll() }
    }
}
