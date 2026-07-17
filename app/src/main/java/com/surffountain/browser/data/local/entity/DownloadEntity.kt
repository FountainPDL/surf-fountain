package com.surffountain.browser.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class DownloadStatus { PENDING, RUNNING, COMPLETE, FAILED, PAUSED }

/**
 * A row per download. Actual file transfer is delegated to Android's own
 * system DownloadManager service (systemDownloadId is its id for this
 * request) rather than reimplemented here — that gets retry, resume, and
 * the system's own progress notification for free instead of as new
 * surface area to get wrong.
 */
@Entity(tableName = "downloads")
data class DownloadEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val systemDownloadId: Long,
    val url: String,
    val fileName: String,
    val mimeType: String?,
    val status: DownloadStatus = DownloadStatus.PENDING,
    val totalBytes: Long = -1,
    val localUri: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
