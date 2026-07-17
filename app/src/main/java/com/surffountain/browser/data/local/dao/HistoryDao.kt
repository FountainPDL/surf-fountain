package com.surffountain.browser.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.surffountain.browser.data.local.entity.HistoryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HistoryDao {

    @Query("SELECT * FROM history ORDER BY visitedAt DESC")
    fun observeAll(): Flow<List<HistoryEntity>>

    @Query(
        """SELECT * FROM history
           WHERE url IN (SELECT url FROM history GROUP BY url ORDER BY MAX(visitedAt) DESC LIMIT :limit)
           GROUP BY url ORDER BY MAX(visitedAt) DESC"""
    )
    fun observeMostRecentDistinct(limit: Int): Flow<List<HistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(entry: HistoryEntity)

    @Query("DELETE FROM history WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM history")
    suspend fun clearAll()
}
