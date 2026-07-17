package com.surffountain.browser.data.repository

import com.surffountain.browser.data.local.dao.DownloadDao
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.local.entity.DownloadStatus
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class DownloadRepository @Inject constructor(
    private val downloadDao: DownloadDao
) {
    fun observeDownloads(): Flow<List<DownloadEntity>> = downloadDao.observeAll()

    suspend fun recordNewDownload(
        systemDownloadId: Long,
        url: String,
        fileName: String,
        mimeType: String?
    ): Long = downloadDao.insert(
        DownloadEntity(
            systemDownloadId = systemDownloadId,
            url = url,
            fileName = fileName,
            mimeType = mimeType,
            status = DownloadStatus.RUNNING
        )
    )

    suspend fun markStatus(systemDownloadId: Long, status: DownloadStatus, localUri: String?, totalBytes: Long) {
        downloadDao.updateStatus(systemDownloadId, status, localUri, totalBytes)
    }

    suspend fun delete(id: Long) = downloadDao.delete(id)

    suspend fun clearAll() = downloadDao.clearAll()
}
