package com.surffountain.browser.downloads

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.surffountain.browser.data.local.entity.DownloadStatus
import com.surffountain.browser.data.repository.DownloadRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Registered dynamically (SurfFountainApplication.onCreate) rather than in
 * the manifest — implicit broadcast manifest registration has been
 * restricted since Android 8, and a process-lifetime dynamic registration
 * is the compatible option that still catches a download finishing while
 * the user isn't looking at the Downloads screen.
 */
class DownloadCompletionReceiver(
    private val repository: DownloadRepository,
    private val scope: CoroutineScope
) : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val systemId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
        if (systemId == -1L) return

        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(systemId))
        cursor.use {
            if (it.moveToFirst()) {
                val statusIdx = it.getColumnIndex(DownloadManager.COLUMN_STATUS)
                val uriIdx = it.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)
                val bytesIdx = it.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
                val systemStatus = if (statusIdx >= 0) it.getInt(statusIdx) else -1
                val localUri = if (uriIdx >= 0) it.getString(uriIdx) else null
                val totalBytes = if (bytesIdx >= 0) it.getLong(bytesIdx) else -1L
                val status = if (systemStatus == DownloadManager.STATUS_SUCCESSFUL) {
                    DownloadStatus.COMPLETE
                } else {
                    DownloadStatus.FAILED
                }
                scope.launch { repository.markStatus(systemId, status, localUri, totalBytes) }
            }
        }
    }
}
