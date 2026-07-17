package com.surffountain.browser.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.local.entity.DownloadStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface DownloadDao {

    @Query("SELECT * FROM downloads ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<DownloadEntity>>

    @Insert
    suspend fun insert(download: DownloadEntity): Long

    @Query("SELECT * FROM downloads WHERE systemDownloadId = :systemDownloadId LIMIT 1")
    suspend fun findBySystemId(systemDownloadId: Long): DownloadEntity?

    @Query(
        "UPDATE downloads SET status = :status, localUri = :localUri, totalBytes = :totalBytes " +
            "WHERE systemDownloadId = :systemDownloadId"
    )
    suspend fun updateStatus(
        systemDownloadId: Long,
        status: DownloadStatus,
        localUri: String?,
        totalBytes: Long
    )

    @Query("DELETE FROM downloads WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM downloads")
    suspend fun clearAll()
}
