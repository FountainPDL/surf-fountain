package com.surffountain.browser.data.repository

import com.surffountain.browser.data.local.dao.TabDao
import com.surffountain.browser.data.local.entity.TabEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Persists the "which tabs are open" list. See TabEntity's kdoc for exactly
 * what is and isn't restored across a full process death.
 */
class TabRepository @Inject constructor(
    private val tabDao: TabDao
) {
    fun observeTabs(): Flow<List<TabEntity>> = tabDao.observeAll()

    suspend fun getSavedTabs(): List<TabEntity> = tabDao.getAllOnce()

    suspend fun saveTab(tab: TabEntity) = tabDao.upsert(tab)

    suspend fun saveTabs(tabs: List<TabEntity>) = tabDao.upsertAll(tabs)

    suspend fun deleteTab(id: String) = tabDao.delete(id)

    suspend fun clearAll() = tabDao.clearAll()
}
