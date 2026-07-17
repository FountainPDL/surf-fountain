package com.surffountain.browser.bookmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.local.entity.BookmarkEntity
import com.surffountain.browser.data.repository.BookmarkRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class BookmarksViewModel @Inject constructor(
    private val bookmarkRepository: BookmarkRepository
) : ViewModel() {
    val bookmarks: StateFlow<List<BookmarkEntity>> = bookmarkRepository.observeBookmarks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun delete(bookmark: BookmarkEntity) {
        viewModelScope.launch { bookmarkRepository.removeBookmark(bookmark.url) }
    }

    /** Surf Fountain exclusive feature, not a stub — see BookmarkEntity.note. */
    fun setNote(url: String, note: String?) {
        viewModelScope.launch { bookmarkRepository.setNote(url, note) }
    }
}
