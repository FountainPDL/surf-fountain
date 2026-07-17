package com.surffountain.browser.data.repository

import com.surffountain.browser.data.local.dao.HistoryDao
import com.surffountain.browser.data.local.entity.HistoryEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class HistoryRepository @Inject constructor(
    private val historyDao: HistoryDao
) {
    fun observeHistory(): Flow<List<HistoryEntity>> = historyDao.observeAll()

    fun observeMostVisited(limit: Int = 8): Flow<List<HistoryEntity>> =
        historyDao.observeMostRecentDistinct(limit)

    suspend fun recordVisit(url: String, title: String) {
        historyDao.insert(HistoryEntity(url = url, title = title))
    }

    suspend fun deleteEntry(id: Long) {
        historyDao.delete(id)
    }

    suspend fun clearAll() {
        historyDao.clearAll()
    }
}
