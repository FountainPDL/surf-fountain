package com.surffountain.browser.data.repository

import com.surffountain.browser.data.local.dao.BookmarkDao
import com.surffountain.browser.data.local.entity.BookmarkEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class BookmarkRepository @Inject constructor(
    private val bookmarkDao: BookmarkDao
) {
    fun observeBookmarks(): Flow<List<BookmarkEntity>> = bookmarkDao.observeAll()

    fun observeIsBookmarked(url: String): Flow<Boolean> = bookmarkDao.observeIsBookmarked(url)

    suspend fun addBookmark(url: String, title: String) {
        bookmarkDao.insert(BookmarkEntity(url = url, title = title))
    }

    suspend fun removeBookmark(url: String) {
        bookmarkDao.deleteByUrl(url)
    }

    suspend fun toggleBookmark(url: String, title: String, currentlyBookmarked: Boolean) {
        if (currentlyBookmarked) removeBookmark(url) else addBookmark(url, title)
    }

    /** Surf Fountain exclusive: private per-site notes — see BookmarkEntity. */
    suspend fun setNote(url: String, note: String?) {
        bookmarkDao.updateNote(url, note?.ifBlank { null })
    }
}
