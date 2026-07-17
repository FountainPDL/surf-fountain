#!/usr/bin/env bash
# apply-brave-ui-and-features.sh
#
# Surf Fountain — Brave-style UI overhaul + feature batch:
#   - purple/red theme, gradient New Tab page, Privacy Stats widget
#   - comprehensive Settings + overflow menu (Brave's structure), with a
#     'Coming Soon' badge/dialog on every not-yet-built entry
#   - real Download Manager (system DownloadManager + Room + Downloads screen)
#   - real multi-engine search picker (custom URL supported)
#   - PDL AI chat UI (model connection intentionally stubbed — see chat itself)
#   - About screen (FountainPDL Ministry)
#   - Site Notes (real, in Bookmarks) — one of 3 promised exclusive features;
#     Content Downloader + Privacy Digest are stub entries in Settings for now
#   - CI hardening: debug/nightly builds now REFUSE to run unsigned instead of
#     silently falling back — this is the fix for the package-conflict install
#     failure. If you haven't run scripts/create_keystore.sh yet, do that first
#     or your next CI run will fail on purpose (see docs/SIGNING.md).
#
# Run from the root of your surf-fountain repo: bash apply-brave-ui-and-features.sh
#
# NOTE: this bumps the Room database version (Downloads table + bookmark notes
# added) with fallbackToDestructiveMigration — local bookmarks/history/tabs on
# your device reset ONE TIME after this update installs. See di/DatabaseModule.kt.

set -euo pipefail
echo "Applying Brave-style UI overhaul + feature batch..."

mkdir -p \
  .github/workflows \
  app/src/main \
  app/src/main/java/com/surffountain/browser \
  app/src/main/java/com/surffountain/browser/about \
  app/src/main/java/com/surffountain/browser/bookmarks \
  app/src/main/java/com/surffountain/browser/browser \
  app/src/main/java/com/surffountain/browser/browser/model \
  app/src/main/java/com/surffountain/browser/browser/webview \
  app/src/main/java/com/surffountain/browser/data/local \
  app/src/main/java/com/surffountain/browser/data/local/dao \
  app/src/main/java/com/surffountain/browser/data/local/entity \
  app/src/main/java/com/surffountain/browser/data/preferences \
  app/src/main/java/com/surffountain/browser/data/repository \
  app/src/main/java/com/surffountain/browser/di \
  app/src/main/java/com/surffountain/browser/downloads \
  app/src/main/java/com/surffountain/browser/home \
  app/src/main/java/com/surffountain/browser/pdlai \
  app/src/main/java/com/surffountain/browser/search \
  app/src/main/java/com/surffountain/browser/settings \
  app/src/main/java/com/surffountain/browser/ui/components \
  app/src/main/java/com/surffountain/browser/ui/navigation \
  app/src/main/java/com/surffountain/browser/ui/theme \
  app/src/main/res/values

echo '  writing app/src/main/java/com/surffountain/browser/about/AboutScreen.kt'
cat > app/src/main/java/com/surffountain/browser/about/AboutScreen.kt << 'SFEOF'
package com.surffountain.browser.about

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.surffountain.browser.BuildConfig
import com.surffountain.browser.R
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(onBack: () -> Unit) {
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_about)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(16.dp))
            Text(
                stringResource(R.string.app_name),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                stringResource(R.string.tagline),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(8.dp))
            Text(
                stringResource(R.string.settings_version, BuildConfig.VERSION_NAME),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(32.dp))
            Text(
                stringResource(R.string.about_made_by),
                style = MaterialTheme.typography.bodyLarge,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Spacer(Modifier.height(24.dp))
            OutlinedButton(onClick = {
                runCatching {
                    context.startActivity(
                        Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/FountainPDL/surf-fountain"))
                    )
                }
            }) {
                Text(stringResource(R.string.about_view_source))
            }
            Spacer(Modifier.height(32.dp))
            Text(
                stringResource(R.string.about_open_source_notice),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/local/dao/DownloadDao.kt'
cat > app/src/main/java/com/surffountain/browser/data/local/dao/DownloadDao.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/local/entity/DownloadEntity.kt'
cat > app/src/main/java/com/surffountain/browser/data/local/entity/DownloadEntity.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/repository/DownloadRepository.kt'
cat > app/src/main/java/com/surffountain/browser/data/repository/DownloadRepository.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/downloads/DownloadCompletionReceiver.kt'
cat > app/src/main/java/com/surffountain/browser/downloads/DownloadCompletionReceiver.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/downloads/DownloadStarter.kt'
cat > app/src/main/java/com/surffountain/browser/downloads/DownloadStarter.kt << 'SFEOF'
package com.surffountain.browser.downloads

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.webkit.CookieManager
import android.webkit.URLUtil

/**
 * Hands the actual file transfer to Android's own DownloadManager system
 * service rather than reimplementing HTTP downloading — that gets retry,
 * resume, background continuation, and the system's own progress
 * notification for free, in exchange for a handful of setup calls here
 * instead of hundreds of lines of new networking code.
 */
object DownloadStarter {

    fun enqueue(
        context: Context,
        url: String,
        userAgent: String?,
        contentDisposition: String?,
        mimeType: String?
    ): Pair<Long, String> {
        val fileName = URLUtil.guessFileName(url, contentDisposition, mimeType)
        val request = DownloadManager.Request(Uri.parse(url)).apply {
            setTitle(fileName)
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            setAllowedOverMeteredNetwork(true)
            setAllowedOverRoaming(true)
            val cookie = CookieManager.getInstance().getCookie(url)
            if (!cookie.isNullOrBlank()) addRequestHeader("Cookie", cookie)
            if (!userAgent.isNullOrBlank()) addRequestHeader("User-Agent", userAgent)
        }
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val systemId = manager.enqueue(request)
        return systemId to fileName
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/downloads/DownloadsScreen.kt'
cat > app/src/main/java/com/surffountain/browser/downloads/DownloadsScreen.kt << 'SFEOF'
package com.surffountain.browser.downloads

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.local.entity.DownloadStatus
import com.surffountain.browser.ui.theme.FountainPurple
import com.surffountain.browser.ui.theme.PureWhite
import com.surffountain.browser.ui.util.AdaptiveContentWidth
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DownloadsScreen(
    onBack: () -> Unit,
    viewModel: DownloadsViewModel = hiltViewModel()
) {
    val downloads by viewModel.downloads.collectAsStateWithLifecycle()
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.downloads_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        if (downloads.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.downloads_empty), style = MaterialTheme.typography.titleMedium)
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = PaddingValues(vertical = 8.dp)) {
                items(downloads, key = { it.id }) { download ->
                    DownloadRow(
                        download = download,
                        onOpen = { openDownload(context, download) },
                        onDelete = { viewModel.delete(download.id) }
                    )
                }
            }
        }
        }
    }
}

@Composable
private fun DownloadRow(download: DownloadEntity, onOpen: () -> Unit, onDelete: () -> Unit) {
    ListItem(
        modifier = Modifier.clickable(enabled = download.status == DownloadStatus.COMPLETE, onClick = onOpen),
        leadingContent = { FileBadge(download.fileName) },
        headlineContent = {
            Text(download.fileName, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
        supportingContent = {
            Text(statusLabel(download), style = MaterialTheme.typography.bodySmall)
        },
        trailingContent = {
            IconButton(onClick = onDelete) {
                Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.action_delete))
            }
        }
    )
}

@Composable
private fun FileBadge(fileName: String) {
    val extension = fileName.substringAfterLast('.', "").take(4).uppercase().ifBlank { "?" }
    Box(
        modifier = Modifier
            .size(40.dp)
            .background(FountainPurple.copy(alpha = 0.85f), RoundedCornerShape(10.dp)),
        contentAlignment = Alignment.Center
    ) {
        Text(text = extension, style = MaterialTheme.typography.labelSmall, color = PureWhite)
    }
}

private fun statusLabel(download: DownloadEntity): String = when (download.status) {
    DownloadStatus.RUNNING, DownloadStatus.PENDING -> "Downloading…"
    DownloadStatus.PAUSED -> "Paused"
    DownloadStatus.FAILED -> "Failed"
    DownloadStatus.COMPLETE -> formatSize(download.totalBytes) + " • " + formatDate(download.createdAt)
}

private fun formatSize(bytes: Long): String {
    if (bytes < 0) return ""
    val kb = bytes / 1024.0
    if (kb < 1024) return "%.0f KB".format(kb)
    return "%.1f MB".format(kb / 1024.0)
}

private fun formatDate(timestamp: Long): String {
    val date = Date(timestamp)
    val today = Calendar.getInstance()
    val target = Calendar.getInstance().apply { time = date }
    return when {
        isSameDay(today, target) -> "Today"
        isSameDay(today.apply { add(Calendar.DAY_OF_YEAR, -1) }, target) -> "Yesterday"
        else -> SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(date)
    }
}

private fun isSameDay(a: Calendar, b: Calendar): Boolean =
    a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)

private fun openDownload(context: android.content.Context, download: DownloadEntity) {
    val uriString = download.localUri ?: return
    try {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uriString), download.mimeType ?: "*/*")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(intent)
    } catch (_: ActivityNotFoundException) {
        // No app installed that can open this file type — nothing to do
        // but avoid crashing.
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/downloads/DownloadsViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/downloads/DownloadsViewModel.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/pdlai/PdlAiMessage.kt'
cat > app/src/main/java/com/surffountain/browser/pdlai/PdlAiMessage.kt << 'SFEOF'
package com.surffountain.browser.pdlai

enum class PdlAiRole { USER, ASSISTANT }

data class PdlAiMessage(
    val id: String,
    val role: PdlAiRole,
    val text: String
)
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/pdlai/PdlAiScreen.kt'
cat > app/src/main/java/com/surffountain/browser/pdlai/PdlAiScreen.kt << 'SFEOF'
package com.surffountain.browser.pdlai

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PdlAiScreen(
    onBack: () -> Unit,
    viewModel: PdlAiViewModel = hiltViewModel()
) {
    val messages by viewModel.messages.collectAsStateWithLifecycle()
    val isSending by viewModel.isSending.collectAsStateWithLifecycle()
    var input by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.pdl_ai_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (messages.isEmpty()) {
                Box(
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(32.dp)) {
                        Text(
                            stringResource(R.string.pdl_ai_empty_title),
                            style = MaterialTheme.typography.titleMedium,
                            textAlign = TextAlign.Center
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            stringResource(R.string.pdl_ai_empty_body),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                LazyColumn(
                    reverseLayout = true,
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (isSending) {
                        item { TypingIndicator() }
                    }
                    items(messages.reversed(), key = { it.id }) { message ->
                        MessageBubble(message)
                    }
                }
            }

            HorizontalDivider()
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(8.dp)
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    placeholder = { Text(stringResource(R.string.pdl_ai_input_hint)) },
                    modifier = Modifier.weight(1f),
                    maxLines = 4
                )
                Spacer(Modifier.width(8.dp))
                IconButton(onClick = {
                    if (input.isNotBlank()) {
                        viewModel.sendMessage(input)
                        input = ""
                    }
                }) {
                    Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = stringResource(R.string.action_send))
                }
            }
        }
    }
}

@Composable
private fun MessageBubble(message: PdlAiMessage) {
    val isUser = message.role == PdlAiRole.USER
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        Surface(
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isUser) 16.dp else 4.dp,
                bottomEnd = if (isUser) 4.dp else 16.dp
            ),
            color = if (isUser) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Text(
                text = message.text,
                style = MaterialTheme.typography.bodyMedium,
                color = if (isUser) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(12.dp)
            )
        }
    }
}

@Composable
private fun TypingIndicator() {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(12.dp)) {
                CircularProgressIndicator(modifier = Modifier.size(14.dp), strokeWidth = 2.dp)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.pdl_ai_typing), style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/pdlai/PdlAiViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/pdlai/PdlAiViewModel.kt << 'SFEOF'
package com.surffountain.browser.pdlai

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * A real, working chat UI wired to a stub model layer — see sendMessage.
 * "just there for now" per the brief: the UI/state machine is genuine,
 * the model connection is the explicitly-not-done part. Swapping the stub
 * reply for a real API call is the only thing that changes when that
 * lands; nothing about the UI or state layer needs to move.
 */
@HiltViewModel
class PdlAiViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    private val _messages = MutableStateFlow<List<PdlAiMessage>>(emptyList())
    val messages: StateFlow<List<PdlAiMessage>> = _messages.asStateFlow()

    private val _isSending = MutableStateFlow(false)
    val isSending: StateFlow<Boolean> = _isSending.asStateFlow()

    val apiKey: StateFlow<String> = settingsDataStore.pdlAiApiKey.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), ""
    )

    fun setApiKey(key: String) {
        viewModelScope.launch { settingsDataStore.setPdlAiApiKey(key) }
    }

    fun sendMessage(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || _isSending.value) return

        _messages.update { it + PdlAiMessage(UUID.randomUUID().toString(), PdlAiRole.USER, trimmed) }
        _isSending.value = true

        viewModelScope.launch {
            val reply = if (apiKey.value.isBlank()) {
                NO_KEY_REPLY
            } else {
                NOT_WIRED_UP_REPLY
            }
            _messages.update { it + PdlAiMessage(UUID.randomUUID().toString(), PdlAiRole.ASSISTANT, reply) }
            _isSending.value = false
        }
    }

    companion object {
        private const val NO_KEY_REPLY =
            "I don't have an API key configured yet — add one in Settings \u2192 PDL AI to enable real " +
                "responses. This chat itself is fully working; the model connection is the part " +
                "that isn't wired up yet."
        private const val NOT_WIRED_UP_REPLY =
            "Thanks for the key! The actual model connection isn't wired up yet, though — this reply " +
                "is a placeholder so the chat UI has something real to show. See docs/ROADMAP.md for " +
                "where this is headed."
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/search/SearchEngine.kt'
cat > app/src/main/java/com/surffountain/browser/search/SearchEngine.kt << 'SFEOF'
package com.surffountain.browser.search

/**
 * The real, buildable version of "FountainSurf": a picker across actual
 * search providers rather than a from-scratch search index (which needs a
 * live backend nothing in this workflow hosts — see docs/ROADMAP.md).
 * template contains a literal "%s" for the query, consumed by
 * UrlUtils.resolveInput.
 */
enum class SearchEngine(val displayName: String, val template: String) {
    DUCKDUCKGO("DuckDuckGo", "https://duckduckgo.com/?q=%s"),
    GOOGLE("Google", "https://www.google.com/search?q=%s"),
    BING("Bing", "https://www.bing.com/search?q=%s"),
    BRAVE_SEARCH("Brave Search", "https://search.brave.com/search?q=%s"),
    STARTPAGE("Startpage", "https://www.startpage.com/sp/search?query=%s"),
    ECOSIA("Ecosia", "https://www.ecosia.org/search?q=%s"),
    YAHOO("Yahoo", "https://search.yahoo.com/search?p=%s");

    companion object {
        fun fromTemplate(template: String): SearchEngine? = values().find { it.template == template }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/search/SearchEngineScreen.kt'
cat > app/src/main/java/com/surffountain/browser/search/SearchEngineScreen.kt << 'SFEOF'
package com.surffountain.browser.search

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchEngineScreen(
    onBack: () -> Unit,
    viewModel: SearchEngineViewModel = hiltViewModel()
) {
    val currentTemplate by viewModel.searchTemplate.collectAsStateWithLifecycle()
    var customUrl by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_search_engine)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(SearchEngine.values().toList()) { engine ->
                ListItem(
                    headlineContent = { Text(engine.displayName) },
                    trailingContent = {
                        RadioButton(selected = engine.template == currentTemplate, onClick = null)
                    },
                    modifier = Modifier.clickable { viewModel.select(engine) }
                )
            }
            item {
                Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Text(stringResource(R.string.settings_custom_search_engine), style = MaterialTheme.typography.titleSmall)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = customUrl,
                        onValueChange = { customUrl = it },
                        placeholder = { Text("https://example.com/search?q=%s") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        supportingText = { Text(stringResource(R.string.settings_custom_search_engine_hint)) },
                        trailingIcon = {
                            TextButton(onClick = { viewModel.setCustomTemplate(customUrl) }) {
                                Text(stringResource(R.string.action_confirm))
                            }
                        }
                    )
                }
            }
        }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/search/SearchEngineViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/search/SearchEngineViewModel.kt << 'SFEOF'
package com.surffountain.browser.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SearchEngineViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    val searchTemplate: StateFlow<String> = settingsDataStore.searchTemplate.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.DEFAULT_SEARCH_TEMPLATE
    )

    fun select(engine: SearchEngine) {
        viewModelScope.launch { settingsDataStore.setSearchTemplate(engine.template) }
    }

    fun setCustomTemplate(template: String) {
        if (template.contains("%s")) {
            viewModelScope.launch { settingsDataStore.setSearchTemplate(template) }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/components/FeatureStubs.kt'
cat > app/src/main/java/com/surffountain/browser/ui/components/FeatureStubs.kt << 'SFEOF'
package com.surffountain.browser.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.surffountain.browser.R

/**
 * The whole app's honesty mechanism for "looks complete, isn't yet":
 * every menu/settings row for a not-built-yet feature gets this badge, and
 * tapping it explains that plainly instead of silently doing nothing or
 * pretending to work. See docs/ROADMAP.md for what's behind each one and
 * roughly when it's landing.
 */
@Composable
fun SoonBadge(modifier: Modifier = Modifier) {
    Surface(
        shape = RoundedCornerShape(6.dp),
        color = MaterialTheme.colorScheme.errorContainer,
        modifier = modifier
    ) {
        Text(
            text = stringResource(R.string.soon_badge),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onErrorContainer,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
        )
    }
}

@Composable
fun ComingSoonDialog(featureName: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(featureName) },
        text = { Text(stringResource(R.string.coming_soon_body)) },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_done)) }
        }
    )
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/theme/Gradients.kt'
cat > app/src/main/java/com/surffountain/browser/ui/theme/Gradients.kt << 'SFEOF'
package com.surffountain.browser.ui.theme

import androidx.compose.ui.graphics.Brush

/** The New Tab page background — purple to red/orange, the same general
 *  diagonal-gradient language a lot of privacy-forward browsers use for
 *  their start page, rendered in Surf Fountain's own palette rather than
 *  anyone else's exact values. */
val FountainNewTabGradient = Brush.linearGradient(
    colors = listOf(FountainVioletContainer, FountainPurpleDark, FountainOrange, FountainRedDark)
)
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/MainActivity.kt'
cat > app/src/main/java/com/surffountain/browser/MainActivity.kt << 'SFEOF'
package com.surffountain.browser

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.settings.SettingsViewModel
import com.surffountain.browser.ui.navigation.SurfFountainNavGraph
import com.surffountain.browser.ui.theme.SurfFountainTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * The one and only Activity. Everything else is a Compose destination in
 * SurfFountainNavGraph — see that file's kdoc for how BrowserViewModel
 * ends up shared across all of them.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Must run before super.onCreate() per the splashscreen library's
        // documented order.
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            val settingsViewModel: SettingsViewModel = hiltViewModel()
            val theme by settingsViewModel.theme.collectAsStateWithLifecycle()
            val darkTheme = when (theme) {
                AppTheme.SYSTEM -> isSystemInDarkTheme()
                AppTheme.LIGHT -> false
                AppTheme.DARK -> true
            }

            val notificationPermissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestPermission(),
                onResult = { /* download notifications just work if granted; nothing breaks if not */ }
            )
            LaunchedEffect(Unit) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val granted = ContextCompat.checkSelfPermission(
                        this@MainActivity,
                        Manifest.permission.POST_NOTIFICATIONS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (!granted) {
                        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    }
                }
            }

            SurfFountainTheme(darkTheme = darkTheme) {
                SurfFountainNavGraph()
            }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/SurfFountainApplication.kt'
cat > app/src/main/java/com/surffountain/browser/SurfFountainApplication.kt << 'SFEOF'
package com.surffountain.browser

import android.app.Application
import android.app.DownloadManager
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.surffountain.browser.data.repository.DownloadRepository
import com.surffountain.browser.downloads.DownloadCompletionReceiver
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import javax.inject.Inject

/**
 * Application entry point. Annotated for Hilt so it generates the
 * top-level dependency container every [Module] in [di] hangs off of.
 *
 * The one thing it does beyond that: registers the download-completion
 * receiver for the app's whole process lifetime, so a download finishing
 * updates its Room record even if the user isn't on the Downloads screen
 * when it happens.
 */
@HiltAndroidApp
class SurfFountainApplication : Application() {

    @Inject
    lateinit var downloadRepository: DownloadRepository

    private val appScope = CoroutineScope(SupervisorJob())
    private var downloadReceiver: DownloadCompletionReceiver? = null

    override fun onCreate() {
        super.onCreate()
        val receiver = DownloadCompletionReceiver(downloadRepository, appScope)
        downloadReceiver = receiver
        ContextCompat.registerReceiver(
            this,
            receiver,
            IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onTerminate() {
        downloadReceiver?.let { unregisterReceiver(it) }
        appScope.cancel()
        super.onTerminate()
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/bookmarks/BookmarksScreen.kt'
cat > app/src/main/java/com/surffountain/browser/bookmarks/BookmarksScreen.kt << 'SFEOF'
package com.surffountain.browser.bookmarks

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.data.local.entity.BookmarkEntity
import com.surffountain.browser.ui.util.AdaptiveContentWidth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    viewModel: BookmarksViewModel = hiltViewModel()
) {
    val bookmarks by viewModel.bookmarks.collectAsStateWithLifecycle()
    var editingNoteFor by remember { mutableStateOf<BookmarkEntity?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.bookmarks_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        if (bookmarks.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(stringResource(R.string.bookmarks_empty), style = MaterialTheme.typography.titleMedium)
                    Text(
                        stringResource(R.string.bookmarks_empty_hint),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(bookmarks, key = { it.id }) { bookmark ->
                    ListItem(
                        headlineContent = {
                            Text(bookmark.title.ifBlank { bookmark.url }, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        supportingContent = {
                            Column {
                                Text(bookmark.url, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                if (!bookmark.note.isNullOrBlank()) {
                                    Text(
                                        text = bookmark.note,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        },
                        trailingContent = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                TextButton(onClick = { editingNoteFor = bookmark }) {
                                    Text(
                                        if (bookmark.note.isNullOrBlank()) {
                                            stringResource(R.string.bookmarks_add_note)
                                        } else {
                                            stringResource(R.string.bookmarks_edit_note)
                                        }
                                    )
                                }
                                IconButton(onClick = { viewModel.delete(bookmark) }) {
                                    Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.bookmarks_delete))
                                }
                            }
                        },
                        modifier = Modifier.clickable { onOpenUrl(bookmark.url) }
                    )
                    HorizontalDivider(modifier = Modifier.height(0.5.dp))
                }
            }
        }
        }
    }

    editingNoteFor?.let { bookmark ->
        var noteText by remember(bookmark.id) { mutableStateOf(bookmark.note.orEmpty()) }
        AlertDialog(
            onDismissRequest = { editingNoteFor = null },
            title = { Text(stringResource(R.string.bookmarks_note_title)) },
            text = {
                OutlinedTextField(
                    value = noteText,
                    onValueChange = { noteText = it },
                    placeholder = { Text(stringResource(R.string.bookmarks_note_hint)) },
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.setNote(bookmark.url, noteText)
                    editingNoteFor = null
                }) { Text(stringResource(R.string.action_confirm)) }
            },
            dismissButton = {
                TextButton(onClick = { editingNoteFor = null }) { Text(stringResource(R.string.action_cancel)) }
            }
        )
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/bookmarks/BookmarksViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/bookmarks/BookmarksViewModel.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt'
cat > app/src/main/java/com/surffountain/browser/browser/BrowserScreen.kt << 'SFEOF'
package com.surffountain.browser.browser

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.ViewGroup
import android.webkit.WebSettings
import android.webkit.WebView
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.browser.webview.SurfFountainWebChromeClient
import com.surffountain.browser.browser.webview.SurfFountainWebViewClient
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.downloads.DownloadStarter
import com.surffountain.browser.home.HomeScreen
import com.surffountain.browser.ui.components.ComingSoonDialog
import com.surffountain.browser.ui.components.SoonBadge

/**
 * Hosts exactly one live WebView for the whole browsing session, reused
 * across every tab (loadUrl for a fresh tab, saveState/restoreState when
 * switching to one that's already been visited) rather than keeping one
 * WebView per tab alive — see BrowserViewModel's kdoc for the full
 * protocol this composable implements.
 */
@SuppressLint("SetJavaScriptEnabled")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowserScreen(
    onNavigateToBookmarks: () -> Unit,
    onNavigateToHistory: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToPdlAi: () -> Unit,
    onNavigateToDownloads: () -> Unit,
    viewModel: BrowserViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val isBookmarked by viewModel.isActiveTabBookmarked.collectAsStateWithLifecycle()
    val shieldsEnabled by viewModel.shieldsEnabled.collectAsStateWithLifecycle()
    val totalBlockedCount by viewModel.totalBlockedCount.collectAsStateWithLifecycle()
    val activeTab = uiState.activeTab

    val webViewRef = remember { mutableStateOf<WebView?>(null) }
    var boundTabId by remember { mutableStateOf<String?>(null) }
    var canGoBack by remember { mutableStateOf(false) }
    var canGoForward by remember { mutableStateOf(false) }
    var menuExpanded by remember { mutableStateOf(false) }
    var showShieldsPanel by remember { mutableStateOf(false) }
    var comingSoonFeature by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    val privateTabsLabel = stringResource(R.string.menu_new_private_tab)
    val tabGroupsLabel = stringResource(R.string.menu_add_to_group)
    val recentTabsLabel = stringResource(R.string.menu_recent_tabs)

    val isHome = activeTab == null ||
        activeTab.url == SettingsDataStore.HOME_SENTINEL ||
        activeTab.url.isBlank()

    // System/predictive back: let the page's own history win first: only
    // fall through to "go to New Tab" once the live WebView has nothing
    // left to go back to.
    BackHandler(enabled = !isHome || canGoBack) {
        val wv = webViewRef.value
        if (wv != null && wv.canGoBack()) {
            wv.goBack()
        } else {
            viewModel.navigateActiveTabTo(SettingsDataStore.HOME_SENTINEL)
        }
    }

    // Tab-switch / explicit-navigation driver. Keyed on the active tab's id
    // AND its navigationRequestId (see Tab.kt) so this fires exactly when
    // it should: a real tab switch, a brand new tab, or an explicit
    // navigate-to-this-url call — never on the WebView's own progress/title
    // callbacks updating the same Tab object.
    LaunchedEffect(activeTab?.id, activeTab?.navigationRequestId) {
        val tab = activeTab ?: return@LaunchedEffect
        val wv = webViewRef.value ?: return@LaunchedEffect

        val previousId = boundTabId
        if (previousId != null && previousId != tab.id) {
            val bundle = Bundle()
            wv.saveState(bundle)
            viewModel.captureWebViewState(previousId, bundle)
        }
        boundTabId = tab.id

        when {
            tab.url == SettingsDataStore.HOME_SENTINEL || tab.url.isBlank() -> Unit
            tab.webViewState != null -> wv.restoreState(tab.webViewState)
            else -> wv.loadUrl(tab.url)
        }
    }

    Scaffold(
        bottomBar = {
            // navigationBarsPadding keeps the toolbar clear of both the
            // gesture-nav pill and the classic 3-button bar — whichever the
            // device is actually using, this reads the correct inset for it.
            Box(modifier = Modifier.navigationBarsPadding()) {
                AddressBar(
                    displayUrl = activeTab?.url?.takeUnless {
                        it == SettingsDataStore.HOME_SENTINEL
                    } ?: "",
                    isSecure = activeTab?.url?.startsWith("https://") == true,
                    isLoading = activeTab?.isLoading == true,
                    progress = activeTab?.progress ?: 0,
                    isBookmarked = isBookmarked,
                    tabCount = uiState.tabs.size,
                    canGoBack = canGoBack,
                    canGoForward = canGoForward,
                    shieldsEnabled = shieldsEnabled,
                    blockedCount = activeTab?.blockedCount ?: 0,
                    onSubmit = { input -> viewModel.submitAddressBarInput(input) },
                    onToggleBookmark = viewModel::toggleBookmarkForActiveTab,
                    onTabsClick = viewModel::showTabSwitcher,
                    onBack = { webViewRef.value?.let { if (it.canGoBack()) it.goBack() } },
                    onForward = { webViewRef.value?.let { if (it.canGoForward()) it.goForward() } },
                    onReload = { webViewRef.value?.reload() },
                    onMenuClick = { menuExpanded = true },
                    onShieldsClick = { showShieldsPanel = true }
                )
                DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.tabs_new_tab)) },
                        onClick = { menuExpanded = false; viewModel.openNewTab() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.menu_new_private_tab)) },
                        trailingIcon = { SoonBadge() },
                        onClick = { menuExpanded = false; comingSoonFeature = privateTabsLabel }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.menu_add_to_group)) },
                        trailingIcon = { SoonBadge() },
                        onClick = { menuExpanded = false; comingSoonFeature = tabGroupsLabel }
                    )
                    HorizontalDivider()
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_history)) },
                        onClick = { menuExpanded = false; onNavigateToHistory() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.downloads_title)) },
                        onClick = { menuExpanded = false; onNavigateToDownloads() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_bookmarks)) },
                        onClick = { menuExpanded = false; onNavigateToBookmarks() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.pdl_ai_title)) },
                        onClick = { menuExpanded = false; onNavigateToPdlAi() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.menu_recent_tabs)) },
                        trailingIcon = { SoonBadge() },
                        onClick = { menuExpanded = false; comingSoonFeature = recentTabsLabel }
                    )
                    HorizontalDivider()
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.nav_settings)) },
                        onClick = { menuExpanded = false; onNavigateToSettings() }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.menu_set_as_default)) },
                        onClick = {
                            menuExpanded = false
                            openDefaultAppsSettings(context)
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            if (isHome) {
                HomeScreen(
                    totalBlockedCount = totalBlockedCount,
                    onSubmitQuery = { query -> viewModel.submitAddressBarInput(query) },
                    onOpenPdlAi = onNavigateToPdlAi
                )
            } else {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { context ->
                        WebView(context).apply {
                            layoutParams = ViewGroup.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            )
                            settings.javaScriptEnabled = true
                            settings.domStorageEnabled = true
                            settings.setSupportZoom(true)
                            settings.builtInZoomControls = true
                            settings.displayZoomControls = false
                            settings.mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
                            webViewClient = SurfFountainWebViewClient(
                                listener = viewModel,
                                isShieldsEnabled = { viewModel.shieldsEnabled.value }
                            )
                            webChromeClient = SurfFountainWebChromeClient(viewModel)
                            setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
                                val (systemId, fileName) = DownloadStarter.enqueue(
                                    context = context,
                                    url = url,
                                    userAgent = userAgent,
                                    contentDisposition = contentDisposition,
                                    mimeType = mimeType
                                )
                                viewModel.recordDownload(systemId, url, fileName, mimeType)
                            }
                            webViewRef.value = this
                        }
                    },
                    update = { wv ->
                        canGoBack = wv.canGoBack()
                        canGoForward = wv.canGoForward()
                    }
                )
            }

            if (uiState.isTabSwitcherVisible) {
                TabSwitcherScreen(
                    tabs = uiState.tabs,
                    activeTabId = uiState.activeTabId,
                    onSelectTab = viewModel::switchToTab,
                    onCloseTab = viewModel::closeTab,
                    onNewTab = { viewModel.openNewTab() },
                    onDismiss = viewModel::hideTabSwitcher
                )
            }
        }
    }

    if (showShieldsPanel) {
        val siteHost = activeTab?.url
            ?.takeUnless { it == SettingsDataStore.HOME_SENTINEL }
            ?.let { runCatching { android.net.Uri.parse(it).host }.getOrNull() }
            .orEmpty()
        ShieldsPanel(
            siteHost = siteHost,
            shieldsEnabled = shieldsEnabled,
            blockedCount = activeTab?.blockedCount ?: 0,
            onToggle = viewModel::setShieldsEnabled,
            onDismiss = { showShieldsPanel = false }
        )
    }

    comingSoonFeature?.let { feature ->
        ComingSoonDialog(featureName = feature, onDismiss = { comingSoonFeature = null })
    }
}

private fun openDefaultAppsSettings(context: Context) {
    val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    runCatching { context.startActivity(intent) }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/BrowserViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/browser/BrowserViewModel.kt << 'SFEOF'
package com.surffountain.browser.browser

import android.graphics.Bitmap
import android.os.Bundle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.browser.model.Tab
import com.surffountain.browser.browser.webview.WebViewEventListener
import com.surffountain.browser.data.local.entity.TabEntity
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.data.repository.BookmarkRepository
import com.surffountain.browser.data.repository.DownloadRepository
import com.surffountain.browser.data.repository.HistoryRepository
import com.surffountain.browser.data.repository.TabRepository
import com.surffountain.browser.utils.UrlUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class BrowserUiState(
    val tabs: List<Tab> = emptyList(),
    val activeTabId: String? = null,
    val isTabSwitcherVisible: Boolean = false
) {
    val activeTab: Tab? get() = tabs.firstOrNull { it.id == activeTabId }
}

/**
 * Owns tab state and is the single [WebViewEventListener] for whichever tab
 * is currently on-screen. It does NOT own the WebView itself (that's a
 * platform View, created and held by BrowserScreen's AndroidView) — this
 * keeps the ViewModel free of Android View references, which is what
 * actually makes it survive configuration changes cleanly and stay unit
 * testable.
 *
 * Tab-switch protocol the Composable follows:
 *  1. call [captureWebViewState] for the outgoing tab (webView.saveState)
 *  2. call [switchToTab]
 *  3. read the new [BrowserUiState.activeTab] and either
 *     webView.restoreState(tab.webViewState) if present, or
 *     webView.loadUrl(tab.url) for a fresh tab.
 */
@HiltViewModel
class BrowserViewModel @Inject constructor(
    private val tabRepository: TabRepository,
    private val historyRepository: HistoryRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val downloadRepository: DownloadRepository,
    private val settingsDataStore: SettingsDataStore
) : ViewModel(), WebViewEventListener {

    private val _tabs = MutableStateFlow<List<Tab>>(emptyList())
    private val _activeTabId = MutableStateFlow<String?>(null)
    private val _isTabSwitcherVisible = MutableStateFlow(false)

    val uiState: StateFlow<BrowserUiState> = combine(
        _tabs, _activeTabId, _isTabSwitcherVisible
    ) { tabs, activeId, switcherVisible ->
        BrowserUiState(tabs, activeId, switcherVisible)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BrowserUiState())

    val isActiveTabBookmarked: StateFlow<Boolean> = combine(_activeTabId, _tabs) { id, tabs ->
        tabs.firstOrNull { it.id == id }?.url
    }.flatMapLatest { url ->
        if (url.isNullOrBlank()) flowOf(false) else bookmarkRepository.observeIsBookmarked(url)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    val searchTemplate: StateFlow<String> = settingsDataStore.searchTemplate.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.DEFAULT_SEARCH_TEMPLATE
    )

    val shieldsEnabled: StateFlow<Boolean> = settingsDataStore.shieldsEnabled.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), true
    )

    fun setShieldsEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsDataStore.setShieldsEnabled(enabled) }
    }

    fun recordDownload(systemDownloadId: Long, url: String, fileName: String, mimeType: String?) {
        viewModelScope.launch {
            downloadRepository.recordNewDownload(systemDownloadId, url, fileName, mimeType)
        }
    }

    /** Persisted all-time total, plus whatever the active tab has blocked
     *  on its current page (not yet flushed — see flushBlockedCountToTotal).
     *  Background tabs never contribute here since only the active tab's
     *  WebView is live and calling onRequestBlocked. */
    val totalBlockedCount: StateFlow<Long> = combine(
        settingsDataStore.totalBlockedCount,
        _activeTabId,
        _tabs
    ) { persisted, activeId, tabs ->
        persisted + (tabs.firstOrNull { it.id == activeId }?.blockedCount ?: 0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L)

    init {
        viewModelScope.launch {
            val saved = tabRepository.getSavedTabs()
            if (saved.isEmpty()) {
                openNewTab()
            } else {
                val restored = saved.map { entity ->
                    Tab(id = entity.id, url = entity.url, title = entity.title, isPrivate = entity.isPrivate)
                }
                _tabs.value = restored
                _activeTabId.value = restored.first().id
            }
        }
    }

    fun openNewTab(url: String? = null, private: Boolean = false) {
        viewModelScope.launch {
            val targetUrl = url ?: settingsDataStore.homePageUrl.first()
            val tab = Tab(
                id = UUID.randomUUID().toString(),
                url = targetUrl,
                isPrivate = private,
                navigationRequestId = 1
            )
            _tabs.value = _tabs.value + tab
            _activeTabId.value = tab.id
            _isTabSwitcherVisible.value = false
            persistTabs()
        }
    }

    fun closeTab(tabId: String) {
        flushBlockedCountToTotal(tabId)
        val remaining = _tabs.value.filterNot { it.id == tabId }
        _tabs.value = remaining
        if (_activeTabId.value == tabId) {
            _activeTabId.value = remaining.lastOrNull()?.id
        }
        viewModelScope.launch {
            tabRepository.deleteTab(tabId)
            if (remaining.isEmpty()) openNewTab()
        }
    }

    fun switchToTab(tabId: String) {
        _activeTabId.value = tabId
        _isTabSwitcherVisible.value = false
    }

    fun showTabSwitcher() {
        _isTabSwitcherVisible.value = true
    }

    fun hideTabSwitcher() {
        _isTabSwitcherVisible.value = false
    }

    /** See the class kdoc for the tab-switch protocol this is step 1 of. */
    fun captureWebViewState(tabId: String, state: Bundle) {
        updateTab(tabId) { it.copy(webViewState = state) }
    }

    fun navigateActiveTabTo(url: String) {
        val id = _activeTabId.value ?: return
        // Dropping the stale saved state + bumping navigationRequestId is
        // what tells BrowserScreen's effect to loadUrl() instead of either
        // restoreState()-ing stale history or silently no-op'ing. Clearing
        // the title specifically for the Home sentinel keeps the tab
        // switcher's "New tab" fallback (Tab.kt / TabSwitcherScreen) from
        // showing the previous page's now-stale title.
        val clearedTitle = url == SettingsDataStore.HOME_SENTINEL
        updateTab(id) {
            it.copy(
                url = url,
                title = if (clearedTitle) "" else it.title,
                webViewState = null,
                navigationRequestId = it.navigationRequestId + 1
            )
        }
    }

    /** Address bar / Home search box entry point: figures out whether
     *  [input] is a URL or a search query and navigates the active tab. */
    fun submitAddressBarInput(input: String) {
        val resolved = UrlUtils.resolveInput(input, searchTemplate.value)
        if (resolved.isNotBlank()) navigateActiveTabTo(resolved)
    }

    fun toggleBookmarkForActiveTab() {
        val tab = uiState.value.activeTab ?: return
        viewModelScope.launch {
            bookmarkRepository.toggleBookmark(
                url = tab.url,
                title = tab.title.ifBlank { tab.url },
                currentlyBookmarked = isActiveTabBookmarked.value
            )
        }
    }

    // ---- WebViewEventListener, driven by the active tab's WebView ---------

    override fun onPageStarted(url: String) {
        val id = _activeTabId.value ?: return
        flushBlockedCountToTotal(id)
        updateTab(id) { it.copy(url = url, isLoading = true, blockedCount = 0) }
    }

    override fun onPageFinished(url: String, title: String?) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(url = url, isLoading = false, title = title ?: it.title) }
        persistTabs()
        val tab = _tabs.value.firstOrNull { it.id == id } ?: return
        if (!tab.isPrivate) {
            viewModelScope.launch {
                historyRepository.recordVisit(tab.url, tab.title.ifBlank { tab.url })
            }
        }
    }

    override fun onProgressChanged(progress: Int) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(progress = progress) }
    }

    override fun onReceivedTitle(title: String) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(title = title) }
    }

    override fun onReceivedIcon(icon: Bitmap?) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(favicon = icon) }
    }

    override fun onRequestBlocked(host: String) {
        val id = _activeTabId.value ?: return
        updateTab(id) { it.copy(blockedCount = it.blockedCount + 1) }
    }

    // ---- internal -----------------------------------------------------------

    /**
     * Uses StateFlow's atomic update{} rather than a plain read-modify-write
     * of .value — shouldInterceptRequest can fire from multiple concurrent
     * background-thread calls (a page loading several sub-resources in
     * parallel), and a plain get-then-set here could lose an update under
     * that concurrency. update{} retries under contention instead.
     */
    private fun updateTab(id: String, transform: (Tab) -> Tab) {
        _tabs.update { tabs -> tabs.map { if (it.id == id) transform(it) else it } }
    }

    private fun flushBlockedCountToTotal(tabId: String) {
        val count = _tabs.value.firstOrNull { it.id == tabId }?.blockedCount ?: 0
        if (count > 0) {
            viewModelScope.launch { settingsDataStore.addToBlockedCount(count.toLong()) }
        }
    }

    private fun persistTabs() {
        viewModelScope.launch {
            val entities = _tabs.value.filterNot { it.isPrivate }.mapIndexed { index, tab ->
                TabEntity(
                    id = tab.id,
                    url = tab.url,
                    title = tab.title,
                    position = index,
                    isPrivate = tab.isPrivate
                )
            }
            tabRepository.saveTabs(entities)
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/model/Tab.kt'
cat > app/src/main/java/com/surffountain/browser/browser/model/Tab.kt << 'SFEOF'
package com.surffountain.browser.browser.model

import android.graphics.Bitmap
import android.os.Bundle

/**
 * In-memory tab state. Deliberately separate from [TabEntity][com.surffountain.browser.data.local.entity.TabEntity],
 * which is the persisted subset (no Bitmap, no WebView Bundle — see that
 * class's kdoc for why).
 */
data class Tab(
    val id: String,
    val url: String = "",
    val title: String = "",
    val isPrivate: Boolean = false,
    val favicon: Bitmap? = null,
    val webViewState: Bundle? = null,
    val isLoading: Boolean = false,
    val progress: Int = 0,
    /**
     * Bumped only by explicit navigation (address bar submit, bookmark tap,
     * Home button, new tab) — never by the WebView's own onPageStarted/
     * onPageFinished callbacks. BrowserScreen's LaunchedEffect keys on this
     * alongside [id] so it can tell "the user asked to go somewhere new"
     * apart from "the page the WebView is already loading reported its
     * own progress," without which every in-page link click would
     * re-trigger a redundant loadUrl() on the page it's already loading.
     */
    val navigationRequestId: Int = 0,
    /** Ads/trackers blocked on the current page load. Reset to 0 in
     *  BrowserViewModel.onPageStarted, incremented via onRequestBlocked. */
    val blockedCount: Int = 0
)
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/webview/WebViewEventListener.kt'
cat > app/src/main/java/com/surffountain/browser/browser/webview/WebViewEventListener.kt << 'SFEOF'
package com.surffountain.browser.browser.webview

import android.graphics.Bitmap

/**
 * Decouples SurfFountainWebViewClient/SurfFountainWebChromeClient (which
 * must extend Android framework classes) from whatever owns the tab state
 * — BrowserViewModel implements this rather than the clients holding a
 * direct ViewModel reference.
 */
interface WebViewEventListener {
    fun onPageStarted(url: String)
    fun onPageFinished(url: String, title: String?)
    fun onProgressChanged(progress: Int)
    fun onReceivedTitle(title: String)
    fun onReceivedIcon(icon: Bitmap?)
    /** A sub-resource request was blocked by Shields. Called off the main
     *  thread — see SurfFountainWebViewClient.shouldInterceptRequest. */
    fun onRequestBlocked(host: String)
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/webview/SurfFountainWebViewClient.kt'
cat > app/src/main/java/com/surffountain/browser/browser/webview/SurfFountainWebViewClient.kt << 'SFEOF'
package com.surffountain.browser.browser.webview

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import com.surffountain.browser.privacy.AdBlockEngine
import java.io.ByteArrayInputStream

/**
 * Phase 0 policy (still true): let the WebView handle http/https itself,
 * hand any other scheme (tel:, mailto:, market:, intent:, ...) to the OS.
 *
 * Shields: [shouldInterceptRequest] runs on a background thread (WebView's
 * own contract, not a choice made here) for every sub-resource a page
 * loads. Main-frame navigations are never blocked here — only a site's own
 * sub-resources — so typing a tracker's domain directly still loads
 * something instead of a blank page.
 */
class SurfFountainWebViewClient(
    private val listener: WebViewEventListener,
    private val isShieldsEnabled: () -> Boolean,
    private val allowlistForCurrentSite: () -> Set<String> = { emptySet() }
) : WebViewClient() {

    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        url?.let(listener::onPageStarted)
    }

    override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        url?.let { listener.onPageFinished(it, view?.title) }
    }

    override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
        if (request == null || request.isForMainFrame) {
            return super.shouldInterceptRequest(view, request)
        }
        val host = request.url?.host
        return if (AdBlockEngine.isBlocked(host, isShieldsEnabled(), allowlistForCurrentSite())) {
            listener.onRequestBlocked(host.orEmpty())
            WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
        } else {
            super.shouldInterceptRequest(view, request)
        }
    }

    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
        val uri = request?.url ?: return false
        return when (uri.scheme) {
            "http", "https" -> false
            else -> {
                try {
                    view?.context?.startActivity(Intent(Intent.ACTION_VIEW, uri))
                } catch (_: ActivityNotFoundException) {
                    // No app can handle it — silently ignore rather than crash.
                }
                true
            }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/browser/AddressBar.kt'
cat > app/src/main/java/com/surffountain/browser/browser/AddressBar.kt << 'SFEOF'
package com.surffountain.browser.browser

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.surffountain.browser.R

@Composable
fun AddressBar(
    displayUrl: String,
    isSecure: Boolean,
    isLoading: Boolean,
    progress: Int,
    isBookmarked: Boolean,
    tabCount: Int,
    canGoBack: Boolean,
    canGoForward: Boolean,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onSubmit: (String) -> Unit,
    onToggleBookmark: () -> Unit,
    onTabsClick: () -> Unit,
    onBack: () -> Unit,
    onForward: () -> Unit,
    onReload: () -> Unit,
    onMenuClick: () -> Unit,
    onShieldsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colorScheme = MaterialTheme.colorScheme

    Column(modifier = modifier) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(start = 4.dp, end = 8.dp)
        ) {
            IconButton(onClick = onBack, enabled = canGoBack) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.action_back),
                    tint = if (canGoBack) colorScheme.onSurface else colorScheme.onSurface.copy(alpha = 0.3f)
                )
            }
            IconButton(onClick = onForward, enabled = canGoForward) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = stringResource(R.string.action_forward),
                    tint = if (canGoForward) colorScheme.onSurface else colorScheme.onSurface.copy(alpha = 0.3f)
                )
            }

            Surface(
                shape = RoundedCornerShape(20.dp),
                color = colorScheme.surfaceVariant,
                modifier = Modifier.weight(1f).height(42.dp)
            ) {
                AddressField(
                    displayUrl = displayUrl,
                    isSecure = isSecure,
                    shieldsEnabled = shieldsEnabled,
                    blockedCount = blockedCount,
                    onSubmit = onSubmit,
                    onShieldsClick = onShieldsClick
                )
            }

            IconButton(onClick = onReload) {
                Icon(
                    Icons.Filled.Refresh,
                    contentDescription = stringResource(R.string.action_reload),
                    tint = colorScheme.onSurface
                )
            }
            IconButton(onClick = onToggleBookmark) {
                Icon(
                    Icons.Filled.Star,
                    contentDescription = stringResource(
                        if (isBookmarked) R.string.action_remove_bookmark else R.string.action_add_bookmark
                    ),
                    tint = if (isBookmarked) colorScheme.primary else colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
            TabCountButtonSimple(count = tabCount, onClick = onTabsClick, tint = colorScheme.onSurface)
            IconButton(onClick = onMenuClick) {
                Icon(Icons.Filled.MoreVert, contentDescription = stringResource(R.string.settings_title), tint = colorScheme.onSurface)
            }
        }

        if (isLoading) {
            LinearProgressIndicator(
                progress = { (progress.coerceIn(0, 100)) / 100f },
                modifier = Modifier.fillMaxWidth().height(2.dp),
                color = colorScheme.primary,
                trackColor = Color.Transparent
            )
        }
    }
}

@Composable
private fun TabCountButtonSimple(count: Int, onClick: () -> Unit, tint: Color) {
    IconButton(onClick = onClick) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(RoundedCornerShape(6.dp))
                .then(Modifier.background(Color.Transparent)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = if (count > 99) "99+" else count.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = tint,
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .padding(horizontal = 2.dp)
            )
        }
    }
}

@Composable
private fun AddressField(
    displayUrl: String,
    isSecure: Boolean,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onSubmit: (String) -> Unit,
    onShieldsClick: () -> Unit
) {
    var text by remember(displayUrl) { mutableStateOf(TextFieldValue(displayUrl)) }
    val colorScheme = MaterialTheme.colorScheme
    val insecureWarning = displayUrl.isNotEmpty() && !isSecure

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)
    ) {
        ShieldsBadge(
            blockedCount = blockedCount,
            enabled = shieldsEnabled,
            onClick = onShieldsClick
        )
        Box(modifier = Modifier.width(8.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (text.text.isEmpty()) {
                Text(
                    text = stringResource(R.string.address_bar_hint),
                    style = MaterialTheme.typography.bodyMedium,
                    color = colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }
            BasicTextField(
                value = text,
                onValueChange = { text = it },
                singleLine = true,
                textStyle = MaterialTheme.typography.bodyMedium.copy(
                    color = if (insecureWarning) colorScheme.error else colorScheme.onSurface
                ),
                cursorBrush = SolidColor(colorScheme.primary),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go, keyboardType = KeyboardType.Uri),
                keyboardActions = KeyboardActions(onGo = {
                    onSubmit(text.text)
                }),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Replaces a generic padlock icon with something actually useful: tap it
 * to see (and toggle) Shields for this site. Shows the blocked-on-this-page
 * count once anything's been blocked, a plain dot before that. Deliberately
 * not a literal shield glyph — that specific icon isn't in the core
 * Material icon set (material-icons-extended only), and a custom badge is
 * closer to how Brave itself does this (a count, not a generic icon) anyway.
 */
@Composable
private fun ShieldsBadge(blockedCount: Int, enabled: Boolean, onClick: () -> Unit) {
    val tint = if (enabled) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    }
    Box(
        modifier = Modifier
            .size(24.dp)
            .clip(CircleShape)
            .background(tint.copy(alpha = 0.15f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (blockedCount > 0) {
            Text(
                text = if (blockedCount > 99) "99+" else blockedCount.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = tint,
                fontSize = 9.sp
            )
        } else {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(tint)
            )
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/local/SurfFountainDatabase.kt'
cat > app/src/main/java/com/surffountain/browser/data/local/SurfFountainDatabase.kt << 'SFEOF'
package com.surffountain.browser.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.surffountain.browser.data.local.dao.BookmarkDao
import com.surffountain.browser.data.local.dao.DownloadDao
import com.surffountain.browser.data.local.dao.HistoryDao
import com.surffountain.browser.data.local.dao.TabDao
import com.surffountain.browser.data.local.entity.BookmarkEntity
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.local.entity.HistoryEntity
import com.surffountain.browser.data.local.entity.TabEntity

@Database(
    entities = [BookmarkEntity::class, HistoryEntity::class, TabEntity::class, DownloadEntity::class],
    version = 2,
    exportSchema = true
)
abstract class SurfFountainDatabase : RoomDatabase() {
    abstract fun bookmarkDao(): BookmarkDao
    abstract fun historyDao(): HistoryDao
    abstract fun tabDao(): TabDao
    abstract fun downloadDao(): DownloadDao

    companion object {
        const val DATABASE_NAME = "surf_fountain.db"
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/local/dao/BookmarkDao.kt'
cat > app/src/main/java/com/surffountain/browser/data/local/dao/BookmarkDao.kt << 'SFEOF'
package com.surffountain.browser.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.surffountain.browser.data.local.entity.BookmarkEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BookmarkDao {

    @Query("SELECT * FROM bookmarks ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<BookmarkEntity>>

    @Query("SELECT EXISTS(SELECT 1 FROM bookmarks WHERE url = :url)")
    fun observeIsBookmarked(url: String): Flow<Boolean>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(bookmark: BookmarkEntity)

    @Query("DELETE FROM bookmarks WHERE url = :url")
    suspend fun deleteByUrl(url: String)

    @Query("UPDATE bookmarks SET note = :note WHERE url = :url")
    suspend fun updateNote(url: String, note: String?)

    @Delete
    suspend fun delete(bookmark: BookmarkEntity)
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/local/entity/BookmarkEntity.kt'
cat > app/src/main/java/com/surffountain/browser/data/local/entity/BookmarkEntity.kt << 'SFEOF'
package com.surffountain.browser.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * A saved page. [folder] is nullable and unused by any UI yet — it exists
 * now so the Bookmarks phase (folders, tags, sort) can land as a pure
 * additive change instead of a schema migration.
 */
@Entity(
    tableName = "bookmarks",
    indices = [Index(value = ["url"], unique = true)]
)
data class BookmarkEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val url: String,
    val title: String,
    val folder: String? = null,
    /** Surf Fountain exclusive: a private note attached to a saved page —
     *  "use this account", "check back for restock", etc. Not a Brave
     *  feature; see docs/ROADMAP.md. */
    val note: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt'
cat > app/src/main/java/com/surffountain/browser/data/preferences/SettingsDataStore.kt << 'SFEOF'
package com.surffountain.browser.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "surf_fountain_settings")

enum class AppTheme { SYSTEM, LIGHT, DARK }

/**
 * Small, flat key-value settings. FountainSurf (the in-house search
 * provider) needs a live backend and isn't built yet, so the default
 * search/home engine here is a real, working one (DuckDuckGo, in keeping
 * with "Private" being half the app's tagline) rather than a placeholder
 * URL that goes nowhere. The Search phase adds a proper multi-engine
 * picker; this key is where it plugs in.
 */
@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val HOME_PAGE_URL = stringPreferencesKey("home_page_url")
        val SEARCH_TEMPLATE = stringPreferencesKey("search_template")
        val SHIELDS_ENABLED = booleanPreferencesKey("shields_enabled")
        val TOTAL_BLOCKED_COUNT = longPreferencesKey("total_blocked_count")
        val PDL_AI_API_KEY = stringPreferencesKey("pdl_ai_api_key")
    }

    val theme: Flow<AppTheme> = context.dataStore.data.map { prefs ->
        when (prefs[Keys.THEME]) {
            "LIGHT" -> AppTheme.LIGHT
            "DARK" -> AppTheme.DARK
            else -> AppTheme.SYSTEM
        }
    }

    /** What a new tab, and the toolbar Home button, navigate to. Defaults
     *  to the native New-Tab page rather than an external URL — the same
     *  default every mainstream mobile browser ships with. */
    val homePageUrl: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.HOME_PAGE_URL] ?: HOME_SENTINEL
    }

    /** URL template (containing a literal "%s") used to turn a typed or
     *  home-screen search query into a URL. DuckDuckGo by default, in
     *  keeping with "Private" being half the app's tagline; becomes a full
     *  multi-engine picker in the Search phase. */
    val searchTemplate: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.SEARCH_TEMPLATE] ?: DEFAULT_SEARCH_TEMPLATE
    }

    /** Shields — ad/tracker blocking. On by default, in keeping with
     *  "Private" being half the app's tagline. */
    val shieldsEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.SHIELDS_ENABLED] ?: true
    }

    suspend fun setShieldsEnabled(enabled: Boolean) {
        context.dataStore.edit { it[Keys.SHIELDS_ENABLED] = enabled }
    }

    /** All-time blocked count, for the New Tab Privacy Stats widget.
     *  BrowserViewModel flushes each page's live count in here as that
     *  page is navigated away from or its tab closes — see its kdoc. */
    val totalBlockedCount: Flow<Long> = context.dataStore.data.map { prefs ->
        prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
    }

    suspend fun addToBlockedCount(delta: Long) {
        if (delta <= 0) return
        context.dataStore.edit { prefs ->
            val current = prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
            prefs[Keys.TOTAL_BLOCKED_COUNT] = current + delta
        }
    }

    /** Stored in plain DataStore for now, not Android Keystore-encrypted —
     *  fine for local development, not where this should stay once PDL AI
     *  actually makes calls with it. Flagged here on purpose rather than
     *  quietly left as a surprise. */
    val pdlAiApiKey: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.PDL_AI_API_KEY] ?: ""
    }

    suspend fun setPdlAiApiKey(key: String) {
        context.dataStore.edit { it[Keys.PDL_AI_API_KEY] = key }
    }

    suspend fun setTheme(theme: AppTheme) {
        context.dataStore.edit { it[Keys.THEME] = theme.name }
    }

    suspend fun setHomePageUrl(url: String) {
        context.dataStore.edit { it[Keys.HOME_PAGE_URL] = url }
    }

    suspend fun setSearchTemplate(template: String) {
        context.dataStore.edit { it[Keys.SEARCH_TEMPLATE] = template }
    }

    companion object {
        /** Not a real network scheme — recognized by BrowserScreen to mean
         *  "render the native Home composable instead of a WebView". */
        const val HOME_SENTINEL = "surf://home"
        const val DEFAULT_SEARCH_TEMPLATE = "https://duckduckgo.com/?q=%s"
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/data/repository/BookmarkRepository.kt'
cat > app/src/main/java/com/surffountain/browser/data/repository/BookmarkRepository.kt << 'SFEOF'
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
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/di/DatabaseModule.kt'
cat > app/src/main/java/com/surffountain/browser/di/DatabaseModule.kt << 'SFEOF'
package com.surffountain.browser.di

import android.content.Context
import androidx.room.Room
import com.surffountain.browser.data.local.SurfFountainDatabase
import com.surffountain.browser.data.local.dao.BookmarkDao
import com.surffountain.browser.data.local.dao.DownloadDao
import com.surffountain.browser.data.local.dao.HistoryDao
import com.surffountain.browser.data.local.dao.TabDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): SurfFountainDatabase =
        Room.databaseBuilder(
            context,
            SurfFountainDatabase::class.java,
            SurfFountainDatabase.DATABASE_NAME
        )
            // Schema is still moving during active development (this build
            // adds Downloads + bookmark notes) — destructive fallback wipes
            // local bookmarks/history/tabs ONCE on this specific update
            // rather than needing a hand-written Migration for every
            // schema tweak this early. Swap for real Migrations once
            // there's real user data worth preserving across upgrades.
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun provideBookmarkDao(database: SurfFountainDatabase): BookmarkDao = database.bookmarkDao()

    @Provides
    fun provideHistoryDao(database: SurfFountainDatabase): HistoryDao = database.historyDao()

    @Provides
    fun provideTabDao(database: SurfFountainDatabase): TabDao = database.tabDao()

    @Provides
    fun provideDownloadDao(database: SurfFountainDatabase): DownloadDao = database.downloadDao()
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/home/HomeScreen.kt'
cat > app/src/main/java/com/surffountain/browser/home/HomeScreen.kt << 'SFEOF'
package com.surffountain.browser.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.R
import com.surffountain.browser.ui.theme.FountainNewTabGradient
import com.surffountain.browser.ui.theme.FountainRedLight
import com.surffountain.browser.ui.theme.PureBlack
import com.surffountain.browser.ui.theme.PureWhite
import com.surffountain.browser.ui.util.AdaptiveContentWidth

/**
 * The native New-Tab page — rendered by BrowserScreen whenever the active
 * tab's url is SettingsDataStore.HOME_SENTINEL, the same way Chrome/Brave
 * show a native page rather than actually navigating anywhere for a blank
 * new tab.
 */
@Composable
fun HomeScreen(
    totalBlockedCount: Long,
    onSubmitQuery: (String) -> Unit,
    onOpenPdlAi: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val mostVisited by viewModel.mostVisited.collectAsStateWithLifecycle()
    var query by remember { mutableStateOf("") }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(FountainNewTabGradient)
    ) {
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(48.dp))
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.headlineMedium,
                color = PureWhite,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(20.dp))

            PrivacyStatsCard(blockedCount = totalBlockedCount)

            Spacer(modifier = Modifier.height(16.dp))

            Surface(
                shape = RoundedCornerShape(24.dp),
                color = PureWhite.copy(alpha = 0.92f),
                modifier = Modifier.fillMaxWidth().height(48.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)
                ) {
                    Icon(Icons.Filled.Search, contentDescription = null, tint = PureBlack.copy(alpha = 0.6f))
                    Spacer(modifier = Modifier.width(10.dp))
                    Box(modifier = Modifier.weight(1f)) {
                        if (query.isEmpty()) {
                            Text(
                                text = stringResource(R.string.address_bar_hint),
                                color = PureBlack.copy(alpha = 0.5f),
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        BasicTextField(
                            value = query,
                            onValueChange = { query = it },
                            singleLine = true,
                            textStyle = MaterialTheme.typography.bodyMedium.copy(color = PureBlack),
                            cursorBrush = SolidColor(PureBlack),
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                            keyboardActions = KeyboardActions(onSearch = { onSubmitQuery(query) }),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            if (mostVisited.isNotEmpty()) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        text = stringResource(R.string.home_most_visited),
                        style = MaterialTheme.typography.labelLarge,
                        color = PureWhite.copy(alpha = 0.85f)
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(mostVisited, key = { it.url }) { entry ->
                        ShortcutTile(
                            title = entry.title.ifBlank { entry.url },
                            onClick = { onSubmitQuery(entry.url) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }

            PdlAiTeaserCard(onClick = onOpenPdlAi)

            Spacer(modifier = Modifier.height(32.dp))
        }
        }
    }
}

@Composable
private fun PrivacyStatsCard(blockedCount: Long) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = PureBlack.copy(alpha = 0.32f),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
            Text(
                text = formatBlockedCount(blockedCount),
                style = MaterialTheme.typography.headlineMedium,
                color = FountainRedLight,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = stringResource(R.string.privacy_stats_label),
                style = MaterialTheme.typography.bodySmall,
                color = PureWhite.copy(alpha = 0.85f)
            )
        }
    }
}

private fun formatBlockedCount(count: Long): String = when {
    count >= 1_000_000 -> "%.1fM".format(count / 1_000_000.0)
    count >= 1_000 -> "%.1fK".format(count / 1_000.0)
    else -> count.toString()
}

@Composable
private fun ShortcutTile(title: String, onClick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(64.dp)
    ) {
        Surface(
            onClick = onClick,
            shape = CircleShape,
            color = PureWhite.copy(alpha = 0.15f),
            modifier = Modifier.size(52.dp)
        ) {
            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                Text(
                    text = title.take(1).uppercase(),
                    style = MaterialTheme.typography.titleMedium,
                    color = PureWhite
                )
            }
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall,
            color = PureWhite.copy(alpha = 0.85f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun PdlAiTeaserCard(onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(20.dp),
        color = PureWhite.copy(alpha = 0.95f),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(20.dp)) {
            Text(
                text = stringResource(R.string.pdl_ai_teaser_title),
                style = MaterialTheme.typography.titleMedium,
                color = PureBlack,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = stringResource(R.string.pdl_ai_teaser_body),
                style = MaterialTheme.typography.bodySmall,
                color = PureBlack.copy(alpha = 0.7f)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Button(onClick = onClick) {
                Text(stringResource(R.string.pdl_ai_get_started))
            }
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/settings/SettingsScreen.kt'
cat > app/src/main/java/com/surffountain/browser/settings/SettingsScreen.kt << 'SFEOF'
package com.surffountain.browser.settings

import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.surffountain.browser.BuildConfig
import com.surffountain.browser.R
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.ui.components.ComingSoonDialog
import com.surffountain.browser.ui.components.SoonBadge
import com.surffountain.browser.ui.util.AdaptiveContentWidth

private data class SettingsEntry(
    val label: String,
    val summary: String? = null,
    val implemented: Boolean,
    val onClick: () -> Unit
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onNavigateToSearchEngine: () -> Unit,
    onNavigateToAbout: () -> Unit,
    onNavigateToBookmarks: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val theme by viewModel.theme.collectAsStateWithLifecycle()
    val homePageUrl by viewModel.homePageUrl.collectAsStateWithLifecycle()
    val shieldsEnabled by viewModel.shieldsEnabled.collectAsStateWithLifecycle()
    var homePageText by remember(homePageUrl) {
        mutableStateOf(if (homePageUrl == SettingsDataStore.HOME_SENTINEL) "" else homePageUrl)
    }
    var comingSoonFeature by remember { mutableStateOf<String?>(null) }
    var showClearDataConfirm by remember { mutableStateOf(false) }
    val context = LocalContext.current

    fun soon(label: String) { comingSoonFeature = label }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                    }
                }
            )
        }
    ) { padding ->
        AdaptiveContentWidth(modifier = Modifier.fillMaxSize().padding(padding)) {
        LazyColumn(modifier = Modifier.fillMaxWidth()) {
            item { SectionHeader(stringResource(R.string.settings_section_features)) }
            item {
                SettingsToggleRow(
                    label = stringResource(R.string.shields_toggle_label),
                    summary = stringResource(R.string.settings_shields_summary),
                    checked = shieldsEnabled,
                    onCheckedChange = viewModel::setShieldsEnabled
                )
            }
            item {
                SettingsRow(stringResource(R.string.settings_pdl_ai), stringResource(R.string.settings_pdl_ai_summary)) {
                    soon(context.getString(R.string.settings_pdl_ai))
                }
            }
            item { StubRow(stringResource(R.string.settings_news)) { soon(context.getString(R.string.settings_news)) } }
            item { StubRow(stringResource(R.string.settings_vpn)) { soon(context.getString(R.string.settings_vpn)) } }

            item { SectionHeader(stringResource(R.string.settings_general)) }
            item {
                SettingsRow(stringResource(R.string.settings_search_engine), null, onNavigateToSearchEngine)
            }
            item {
                HomePageRow(
                    value = homePageText,
                    onValueChange = { homePageText = it },
                    onConfirm = { viewModel.setHomePageUrl(homePageText.ifBlank { SettingsDataStore.HOME_SENTINEL }) }
                )
            }
            item { StubRow(stringResource(R.string.settings_sync)) { soon(context.getString(R.string.settings_sync)) } }
            item {
                SettingsRow(stringResource(R.string.settings_notifications), null) {
                    runCatching {
                        context.startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                        )
                    }
                }
            }
            item { StubRow(stringResource(R.string.settings_site_settings)) { soon(context.getString(R.string.settings_site_settings)) } }
            item {
                SettingsRow(stringResource(R.string.settings_clear_data), stringResource(R.string.settings_clear_data_summary)) {
                    showClearDataConfirm = true
                }
            }

            item { SectionHeader(stringResource(R.string.settings_display)) }
            item {
                Text(
                    stringResource(R.string.settings_theme),
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            item {
                Column(Modifier.selectableGroup().padding(horizontal = 8.dp)) {
                    ThemeOption(AppTheme.SYSTEM, stringResource(R.string.settings_theme_system), theme, viewModel::setTheme)
                    ThemeOption(AppTheme.LIGHT, stringResource(R.string.settings_theme_light), theme, viewModel::setTheme)
                    ThemeOption(AppTheme.DARK, stringResource(R.string.settings_theme_dark), theme, viewModel::setTheme)
                }
            }
            item { StubRow(stringResource(R.string.settings_tabs_groups)) { soon(context.getString(R.string.settings_tabs_groups)) } }
            item { StubRow(stringResource(R.string.settings_new_tab_page)) { soon(context.getString(R.string.settings_new_tab_page)) } }
            item { StubRow(stringResource(R.string.settings_accessibility)) { soon(context.getString(R.string.settings_accessibility)) } }

            item { SectionHeader(stringResource(R.string.settings_passwords_autofill)) }
            item { StubRow(stringResource(R.string.settings_password_manager)) { soon(context.getString(R.string.settings_password_manager)) } }
            item { StubRow(stringResource(R.string.settings_autofill)) { soon(context.getString(R.string.settings_autofill)) } }

            item { SectionHeader(stringResource(R.string.settings_exclusive)) }
            item {
                SettingsRow(
                    stringResource(R.string.settings_site_notes),
                    stringResource(R.string.settings_site_notes_summary),
                    onClick = onNavigateToBookmarks
                )
            }
            item { StubRow(stringResource(R.string.settings_content_downloader)) { soon(context.getString(R.string.settings_content_downloader)) } }
            item {
                SettingsRow(
                    stringResource(R.string.settings_privacy_digest),
                    stringResource(R.string.settings_privacy_digest_summary)
                ) { soon(context.getString(R.string.settings_privacy_digest)) }
            }

            item { SectionHeader(stringResource(R.string.settings_support)) }
            item {
                SettingsRow(stringResource(R.string.settings_send_feedback), null) {
                    runCatching {
                        context.startActivity(
                            Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://github.com/FountainPDL/surf-fountain/issues"))
                        )
                    }
                }
            }

            item { SectionHeader(stringResource(R.string.settings_about_section)) }
            item {
                SettingsRow(stringResource(R.string.settings_about), stringResource(R.string.settings_version, BuildConfig.VERSION_NAME)) {
                    onNavigateToAbout()
                }
            }
            item { Spacer(modifier = Modifier.height(32.dp)) }
        }
        }
    }

    comingSoonFeature?.let { feature ->
        ComingSoonDialog(featureName = feature, onDismiss = { comingSoonFeature = null })
    }

    if (showClearDataConfirm) {
        AlertDialog(
            onDismissRequest = { showClearDataConfirm = false },
            title = { Text(stringResource(R.string.settings_clear_data)) },
            text = { Text(stringResource(R.string.settings_clear_data_confirm_body)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearBrowsingData()
                    showClearDataConfirm = false
                }) { Text(stringResource(R.string.action_delete)) }
            },
            dismissButton = {
                TextButton(onClick = { showClearDataConfirm = false }) { Text(stringResource(R.string.action_cancel)) }
            }
        )
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
    )
}

@Composable
private fun SettingsRow(label: String, summary: String?, onClick: () -> Unit) {
    ListItem(
        headlineContent = { Text(label) },
        supportingContent = if (summary != null) {
            { Text(summary, maxLines = 2, overflow = TextOverflow.Ellipsis) }
        } else {
            null
        },
        modifier = Modifier.clickable(onClick = onClick)
    )
}

@Composable
private fun StubRow(label: String, onClick: () -> Unit) {
    ListItem(
        headlineContent = { Text(label) },
        trailingContent = { SoonBadge() },
        modifier = Modifier.clickable(onClick = onClick)
    )
}

@Composable
private fun SettingsToggleRow(label: String, summary: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    ListItem(
        headlineContent = { Text(label) },
        supportingContent = { Text(summary) },
        trailingContent = { Switch(checked = checked, onCheckedChange = onCheckedChange) },
        modifier = Modifier.clickable { onCheckedChange(!checked) }
    )
}

@Composable
private fun HomePageRow(value: String, onValueChange: (String) -> Unit, onConfirm: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
        Text(stringResource(R.string.settings_home_page), style = MaterialTheme.typography.bodyMedium)
        Spacer(Modifier.height(4.dp))
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = { Text("New Tab page") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            trailingIcon = {
                TextButton(onClick = onConfirm) { Text(stringResource(R.string.action_confirm)) }
            }
        )
    }
}

@Composable
private fun ThemeOption(value: AppTheme, label: String, selected: AppTheme, onSelect: (AppTheme) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = (selected == value), onClick = { onSelect(value) }, role = Role.RadioButton)
            .padding(horizontal = 8.dp, vertical = 8.dp)
    ) {
        RadioButton(selected = (selected == value), onClick = null)
        Spacer(Modifier.width(12.dp))
        Text(label, style = MaterialTheme.typography.bodyLarge)
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/settings/SettingsViewModel.kt'
cat > app/src/main/java/com/surffountain/browser/settings/SettingsViewModel.kt << 'SFEOF'
package com.surffountain.browser.settings

import android.webkit.CookieManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.AppTheme
import com.surffountain.browser.data.preferences.SettingsDataStore
import com.surffountain.browser.data.repository.HistoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore,
    private val historyRepository: HistoryRepository
) : ViewModel() {
    val theme: StateFlow<AppTheme> = settingsDataStore.theme
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AppTheme.SYSTEM)

    val homePageUrl: StateFlow<String> = settingsDataStore.homePageUrl
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsDataStore.HOME_SENTINEL)

    val shieldsEnabled: StateFlow<Boolean> = settingsDataStore.shieldsEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    fun setShieldsEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsDataStore.setShieldsEnabled(enabled) }
    }

    fun setTheme(theme: AppTheme) {
        viewModelScope.launch { settingsDataStore.setTheme(theme) }
    }

    fun setHomePageUrl(url: String) {
        viewModelScope.launch { settingsDataStore.setHomePageUrl(url) }
    }

    /** Clears history (Room) and cookies (WebView) — the two pieces of
     *  "browsing data" Surf Fountain actually accumulates today. Cache/
     *  site-storage clearing lands with the Privacy phase's site settings. */
    fun clearBrowsingData() {
        viewModelScope.launch { historyRepository.clearAll() }
        CookieManager.getInstance().removeAllCookies(null)
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/navigation/Destinations.kt'
cat > app/src/main/java/com/surffountain/browser/ui/navigation/Destinations.kt << 'SFEOF'
package com.surffountain.browser.ui.navigation

sealed class Destination(val route: String) {
    data object Browser : Destination("browser")
    data object Bookmarks : Destination("bookmarks")
    data object History : Destination("history")
    data object Settings : Destination("settings")
    data object PdlAi : Destination("pdl_ai")
    data object Downloads : Destination("downloads")
    data object About : Destination("about")
    data object SearchEngine : Destination("search_engine")
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/navigation/SurfFountainNavGraph.kt'
cat > app/src/main/java/com/surffountain/browser/ui/navigation/SurfFountainNavGraph.kt << 'SFEOF'
package com.surffountain.browser.ui.navigation

import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.surffountain.browser.about.AboutScreen
import com.surffountain.browser.bookmarks.BookmarksScreen
import com.surffountain.browser.browser.BrowserScreen
import com.surffountain.browser.browser.BrowserViewModel
import com.surffountain.browser.downloads.DownloadsScreen
import com.surffountain.browser.history.HistoryScreen
import com.surffountain.browser.pdlai.PdlAiScreen
import com.surffountain.browser.search.SearchEngineScreen
import com.surffountain.browser.settings.SettingsScreen

/**
 * BrowserViewModel is requested once, here, at the graph's top level rather
 * than inside the "browser" composable() block — hiltViewModel() resolves
 * against the nearest ViewModelStoreOwner in the composition, which at
 * this point is the hosting Activity, giving one BrowserViewModel (and
 * therefore one live tab set) shared across every destination. Bookmarks/
 * History only get an onOpenUrl callback, not the ViewModel itself, so
 * they stay decoupled and easy to test on their own.
 */
@Composable
fun SurfFountainNavGraph(navController: NavHostController = rememberNavController()) {
    val browserViewModel: BrowserViewModel = hiltViewModel()

    NavHost(navController = navController, startDestination = Destination.Browser.route) {
        composable(Destination.Browser.route) {
            BrowserScreen(
                viewModel = browserViewModel,
                onNavigateToBookmarks = { navController.navigate(Destination.Bookmarks.route) },
                onNavigateToHistory = { navController.navigate(Destination.History.route) },
                onNavigateToSettings = { navController.navigate(Destination.Settings.route) },
                onNavigateToPdlAi = { navController.navigate(Destination.PdlAi.route) },
                onNavigateToDownloads = { navController.navigate(Destination.Downloads.route) }
            )
        }
        composable(Destination.Bookmarks.route) {
            BookmarksScreen(
                onBack = { navController.popBackStack() },
                onOpenUrl = { url ->
                    browserViewModel.navigateActiveTabTo(url)
                    navController.popBackStack(Destination.Browser.route, inclusive = false)
                }
            )
        }
        composable(Destination.History.route) {
            HistoryScreen(
                onBack = { navController.popBackStack() },
                onOpenUrl = { url ->
                    browserViewModel.navigateActiveTabTo(url)
                    navController.popBackStack(Destination.Browser.route, inclusive = false)
                }
            )
        }
        composable(Destination.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onNavigateToSearchEngine = { navController.navigate(Destination.SearchEngine.route) },
                onNavigateToAbout = { navController.navigate(Destination.About.route) },
                onNavigateToBookmarks = { navController.navigate(Destination.Bookmarks.route) }
            )
        }
        composable(Destination.SearchEngine.route) {
            SearchEngineScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.About.route) {
            AboutScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.PdlAi.route) {
            PdlAiScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.Downloads.route) {
            DownloadsScreen(onBack = { navController.popBackStack() })
        }
    }
}
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/theme/Color.kt'
cat > app/src/main/java/com/surffountain/browser/ui/theme/Color.kt << 'SFEOF'
package com.surffountain.browser.ui.theme

import androidx.compose.ui.graphics.Color

// Core brand palette, taken directly from the app icon so the UI and the
// launcher icon read as the same product.
val FountainPurple = Color(0xFF8B5CF6)
val FountainPurpleDark = Color(0xFF6D28D9)
val FountainPurpleLight = Color(0xFFC4B5FD)
val FountainVioletContainer = Color(0xFF4C1D95)

// Second brand accent — deliberately semantic, not decorative: the
// blocked-trackers count, the New Tab gradient, and "something needs your
// attention" badges all lean on this rather than sprinkling red anywhere
// it doesn't mean something.
val FountainRed = Color(0xFFEF4444)
val FountainRedLight = Color(0xFFFCA5A5)
val FountainRedDark = Color(0xFFB91C1C)
val FountainOrange = Color(0xFFF97316) // the purple->red gradient's midpoint

val PureBlack = Color(0xFF000000)
val NearBlackSurface = Color(0xFF121212)
val NearBlackSurfaceElevated = Color(0xFF1C1B1F)
val PureWhite = Color(0xFFFFFFFF)
val OffWhiteSurface = Color(0xFFFAF9FC)

val DangerRed = FountainRedDark
SFEOF

echo '  writing app/src/main/java/com/surffountain/browser/ui/theme/Theme.kt'
cat > app/src/main/java/com/surffountain/browser/ui/theme/Theme.kt << 'SFEOF'
package com.surffountain.browser.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val FountainDarkScheme = darkColorScheme(
    primary = FountainPurpleLight,
    onPrimary = PureBlack,
    primaryContainer = FountainVioletContainer,
    onPrimaryContainer = FountainPurpleLight,
    secondary = FountainPurple,
    onSecondary = PureBlack,
    tertiary = FountainRedLight,
    onTertiary = PureBlack,
    tertiaryContainer = FountainRedDark,
    onTertiaryContainer = FountainRedLight,
    background = PureBlack,
    onBackground = PureWhite,
    surface = NearBlackSurface,
    onSurface = PureWhite,
    surfaceVariant = NearBlackSurfaceElevated,
    onSurfaceVariant = PureWhite,
    error = DangerRed
)

private val FountainLightScheme = lightColorScheme(
    primary = FountainPurpleDark,
    onPrimary = PureWhite,
    primaryContainer = FountainPurpleLight,
    onPrimaryContainer = FountainVioletContainer,
    secondary = FountainPurple,
    onSecondary = PureWhite,
    tertiary = FountainRedDark,
    onTertiary = PureWhite,
    tertiaryContainer = FountainRedLight,
    onTertiaryContainer = FountainRedDark,
    background = PureWhite,
    onBackground = PureBlack,
    surface = OffWhiteSurface,
    onSurface = PureBlack,
    surfaceVariant = FountainPurpleLight,
    onSurfaceVariant = FountainVioletContainer,
    error = DangerRed
)

/**
 * @param darkTheme resolved light/dark boolean — callers translate the
 *   user's SYSTEM/LIGHT/DARK preference (see AppTheme) into this before
 *   calling in, so this composable itself stays a dumb, testable function
 *   of a single boolean.
 * @param dynamicColor Material You wallpaper-derived color, Android 12+.
 *   Falls back to the brand purple palette below that, or if the user has
 *   disabled it — same convention Android's own reference apps use.
 */
@Composable
fun SurfFountainTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        darkTheme -> FountainDarkScheme
        else -> FountainLightScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = SurfFountainTypography,
        content = content
    )
}
SFEOF

echo '  writing .github/workflows/ci.yml'
cat > .github/workflows/ci.yml << 'SFEOF'
name: CI

# Every push/PR gets linted, tested, and built into a debug APK. This never
# requires Android Studio, a local SDK, or anything beyond what this
# workflow installs itself.

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  build:
    name: Lint, test, and build debug APK
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      # Pinned explicitly rather than left to "latest" — AGP 8.x and
      # Gradle 9.x don't mix (see docs/SIGNING.md / the Gradle-version note
      # in gradle/wrapper/gradle-wrapper.properties). If this exact line is
      # ever the first thing that fails, that's the version to bump.
      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: '8.13'

      # Every build — debug included — is signed with the one persistent
      # keystore (see app/build.gradle.kts). This used to fall back
      # silently to AGP's own throwaway debug keystore when the secrets
      # below weren't set, which is *exactly* what caused a real
      # "package conflicts with an existing package" install failure: two
      # debug builds from two different runs, two different auto-generated
      # keys. It no longer falls back — this step fails loudly instead, so
      # that can't happen silently again.
      - name: Configure signing (required — see docs/SIGNING.md)
        env:
          SF_KEYSTORE_BASE64: ${{ secrets.SF_KEYSTORE_BASE64 }}
          SF_KEYSTORE_PASSWORD: ${{ secrets.SF_KEYSTORE_PASSWORD }}
          SF_KEY_ALIAS: ${{ secrets.SF_KEY_ALIAS }}
          SF_KEY_PASSWORD: ${{ secrets.SF_KEY_PASSWORD }}
        run: |
          if [ -z "$SF_KEYSTORE_BASE64" ]; then
            echo "## :x: Signing secrets are not configured" >> "$GITHUB_STEP_SUMMARY"
            echo "" >> "$GITHUB_STEP_SUMMARY"
            echo "This build was stopped on purpose. Building without the persisted" >> "$GITHUB_STEP_SUMMARY"
            echo "keystore is exactly what causes **\"package conflicts with an existing" >> "$GITHUB_STEP_SUMMARY"
            echo "package\"** when you go to install the next update." >> "$GITHUB_STEP_SUMMARY"
            echo "" >> "$GITHUB_STEP_SUMMARY"
            echo "**Fix (one-time, from Termux):**" >> "$GITHUB_STEP_SUMMARY"
            echo '```' >> "$GITHUB_STEP_SUMMARY"
            echo "scripts/create_keystore.sh" >> "$GITHUB_STEP_SUMMARY"
            echo '```' >> "$GITHUB_STEP_SUMMARY"
            echo "Then add the 4 secrets it prints at:" >> "$GITHUB_STEP_SUMMARY"
            echo "Settings > Secrets and variables > Actions on this repo." >> "$GITHUB_STEP_SUMMARY"
            echo "Full detail: docs/SIGNING.md." >> "$GITHUB_STEP_SUMMARY"
            echo "::error::SF_KEYSTORE_BASE64 is not set — run scripts/create_keystore.sh and add the 4 secrets it prints (docs/SIGNING.md). Builds are intentionally blocked until then to avoid the exact 'package conflicts' bug this exists to prevent."
            exit 1
          fi
          mkdir -p "$RUNNER_TEMP/keystore"
          echo "$SF_KEYSTORE_BASE64" | base64 --decode > "$RUNNER_TEMP/keystore/surffountain.jks"
          {
            echo "SF_KEYSTORE_PATH=$RUNNER_TEMP/keystore/surffountain.jks"
            echo "SF_KEYSTORE_PASSWORD=$SF_KEYSTORE_PASSWORD"
            echo "SF_KEY_ALIAS=$SF_KEY_ALIAS"
            echo "SF_KEY_PASSWORD=$SF_KEY_PASSWORD"
          } >> "$GITHUB_ENV"

      - name: Lint
        run: gradle lintDebug --no-daemon

      - name: Unit tests
        run: gradle testDebugUnitTest --no-daemon

      - name: Build debug APK
        run: gradle assembleDebug --no-daemon

      - name: Upload debug APK
        uses: actions/upload-artifact@v4
        with:
          name: surf-fountain-debug-${{ github.run_number }}
          path: app/build/outputs/apk/debug/*.apk
          if-no-files-found: error

      - name: Upload test + lint reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: reports-${{ github.run_number }}
          path: |
            app/build/reports/
          if-no-files-found: ignore
SFEOF

echo '  writing .github/workflows/nightly.yml'
cat > .github/workflows/nightly.yml << 'SFEOF'
name: Nightly

# A debug build every night, purely so there's always a recent APK to
# sideload without waiting on a manual release. Skips itself automatically
# if nothing changed since the last nightly (no point re-publishing an
# identical APK).

on:
  schedule:
    - cron: '0 9 * * *'   # 09:00 UTC daily
  workflow_dispatch:

concurrency:
  group: nightly
  cancel-in-progress: true

permissions:
  contents: write

jobs:
  nightly:
    name: Nightly debug build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check for new commits since last nightly tag
        id: changes
        run: |
          if git rev-parse nightly >/dev/null 2>&1; then
            if [ -z "$(git log nightly..HEAD --oneline)" ]; then
              echo "has_changes=false" >> "$GITHUB_OUTPUT"
            else
              echo "has_changes=true" >> "$GITHUB_OUTPUT"
            fi
          else
            echo "has_changes=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Set up JDK 21
        if: steps.changes.outputs.has_changes == 'true'
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      - name: Set up Gradle
        if: steps.changes.outputs.has_changes == 'true'
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: '8.13'

      - name: Configure signing (required — see docs/SIGNING.md)
        if: steps.changes.outputs.has_changes == 'true'
        env:
          SF_KEYSTORE_BASE64: ${{ secrets.SF_KEYSTORE_BASE64 }}
          SF_KEYSTORE_PASSWORD: ${{ secrets.SF_KEYSTORE_PASSWORD }}
          SF_KEY_ALIAS: ${{ secrets.SF_KEY_ALIAS }}
          SF_KEY_PASSWORD: ${{ secrets.SF_KEY_PASSWORD }}
        run: |
          if [ -z "$SF_KEYSTORE_BASE64" ]; then
            echo "::error::SF_KEYSTORE_BASE64 is not set — run scripts/create_keystore.sh and add the 4 secrets it prints (docs/SIGNING.md). Nightly is intentionally blocked until then."
            exit 1
          fi
          mkdir -p "$RUNNER_TEMP/keystore"
          echo "$SF_KEYSTORE_BASE64" | base64 --decode > "$RUNNER_TEMP/keystore/surffountain.jks"
          {
            echo "SF_KEYSTORE_PATH=$RUNNER_TEMP/keystore/surffountain.jks"
            echo "SF_KEYSTORE_PASSWORD=$SF_KEYSTORE_PASSWORD"
            echo "SF_KEY_ALIAS=$SF_KEY_ALIAS"
            echo "SF_KEY_PASSWORD=$SF_KEY_PASSWORD"
          } >> "$GITHUB_ENV"

      - name: Build debug APK
        if: steps.changes.outputs.has_changes == 'true'
        run: gradle assembleDebug --no-daemon

      - name: Move nightly tag
        if: steps.changes.outputs.has_changes == 'true'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git tag -f nightly
          git push origin nightly --force

      - name: Publish nightly release
        if: steps.changes.outputs.has_changes == 'true'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release delete nightly --yes || true
          gh release create nightly \
            app/build/outputs/apk/debug/*.apk \
            --title "Nightly (build ${{ github.run_number }})" \
            --notes "Automated nightly debug build. Not signed for production use until secrets are configured — see docs/SIGNING.md." \
            --prerelease
SFEOF

echo '  writing app/src/main/res/values/strings.xml'
cat > app/src/main/res/values/strings.xml << 'SFEOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Surf Fountain</string>
    <string name="tagline">Fast. Private. Powerful.</string>

    <!-- Address bar -->
    <string name="address_bar_hint">Search or enter address</string>
    <string name="action_go">Go</string>
    <string name="action_reload">Reload</string>
    <string name="action_stop">Stop</string>
    <string name="action_back">Back</string>
    <string name="action_forward">Forward</string>
    <string name="action_share">Share</string>
    <string name="action_add_bookmark">Add bookmark</string>
    <string name="action_remove_bookmark">Remove bookmark</string>

    <!-- Tabs -->
    <string name="tabs_new_tab">New tab</string>
    <string name="tabs_close_tab">Close tab</string>
    <string name="tabs_switcher_title">%1$d tabs</string>
    <string name="tabs_empty">No open tabs</string>
    <string name="menu_new_private_tab">New Private Tab</string>
    <string name="menu_add_to_group">Add tab to group</string>
    <string name="menu_recent_tabs">Recent tabs</string>
    <string name="menu_set_as_default">Set as Default Browser</string>

    <!-- Home -->
    <string name="home_most_visited">Shortcuts</string>
    <string name="home_no_history_yet">Sites you visit will show up here</string>
    <string name="privacy_stats_label">Trackers &amp; ads blocked</string>
    <string name="pdl_ai_teaser_title">Meet PDL AI</string>
    <string name="pdl_ai_teaser_body">Your assistant, built into the browser. Summarize pages, ask questions, get things written — privately.</string>
    <string name="pdl_ai_get_started">Get started</string>

    <!-- Bookmarks -->
    <string name="bookmarks_title">Bookmarks</string>
    <string name="bookmarks_empty">No bookmarks yet</string>
    <string name="bookmarks_empty_hint">Tap the star in the address bar to save a page</string>
    <string name="bookmarks_delete">Delete bookmark</string>
    <string name="bookmarks_add_note">Add note</string>
    <string name="bookmarks_edit_note">Edit note</string>
    <string name="bookmarks_note_title">Private note</string>
    <string name="bookmarks_note_hint">Visible only to you, never synced anywhere yet</string>

    <!-- History -->
    <string name="history_title">History</string>
    <string name="history_empty">No browsing history yet</string>
    <string name="history_clear_all">Clear all history</string>
    <string name="history_clear_confirm_title">Clear history?</string>
    <string name="history_clear_confirm_body">This removes every site you\'ve visited from this device. This can\'t be undone.</string>
    <string name="history_delete_item">Remove from history</string>

    <!-- Downloads -->
    <string name="downloads_title">Downloads</string>
    <string name="downloads_empty">No downloads yet</string>

    <!-- Settings -->
    <string name="settings_title">Settings</string>
    <string name="settings_section_features">Features</string>
    <string name="settings_appearance">Appearance</string>
    <string name="settings_theme">Theme</string>
    <string name="settings_theme_system">Match system</string>
    <string name="settings_theme_light">Light</string>
    <string name="settings_theme_dark">Dark</string>
    <string name="settings_privacy">Privacy</string>
    <string name="settings_shields_summary">Block known ad and tracker domains automatically</string>
    <string name="settings_pdl_ai_summary">Your assistant, built into the browser</string>
    <string name="settings_news">News</string>
    <string name="settings_vpn">Firewall + VPN</string>
    <string name="settings_general">General</string>
    <string name="settings_search_engine">Search engine</string>
    <string name="settings_custom_search_engine">Custom search engine</string>
    <string name="settings_custom_search_engine_hint">Must contain %s where the query goes</string>
    <string name="settings_home_page">Home page</string>
    <string name="settings_sync">Sync</string>
    <string name="settings_notifications">Notifications</string>
    <string name="settings_site_settings">Site settings</string>
    <string name="settings_clear_data">Clear browsing data</string>
    <string name="settings_clear_data_summary">History and cookies</string>
    <string name="settings_clear_data_confirm_body">This clears your history and cookies from this device. This can\'t be undone.</string>
    <string name="settings_display">Display</string>
    <string name="settings_tabs_groups">Tabs and tab groups</string>
    <string name="settings_new_tab_page">New Tab page</string>
    <string name="settings_accessibility">Accessibility</string>
    <string name="settings_passwords_autofill">Passwords and Autofill</string>
    <string name="settings_password_manager">Password manager</string>
    <string name="settings_autofill">Autofill services</string>
    <string name="settings_exclusive">Surf Fountain exclusive</string>
    <string name="settings_site_notes">Site Notes</string>
    <string name="settings_site_notes_summary">Private notes on any bookmarked page</string>
    <string name="settings_content_downloader">Content Downloader</string>
    <string name="settings_privacy_digest">Privacy Digest</string>
    <string name="settings_privacy_digest_summary">Your blocking history over time</string>
    <string name="settings_support">Support</string>
    <string name="settings_send_feedback">Send feedback</string>
    <string name="settings_about_section">About</string>
    <string name="settings_about">About Surf Fountain</string>
    <string name="settings_version">Version %1$s</string>
    <string name="about_made_by">Made by FountainPDL Ministry</string>
    <string name="about_view_source">View source on GitHub</string>
    <string name="about_open_source_notice">Built entirely from a phone — Termux, GitHub, and GitHub Actions, no desktop involved.</string>

    <!-- Navigation labels -->
    <string name="nav_home">Home</string>
    <string name="nav_tabs">Tabs</string>
    <string name="nav_bookmarks">Bookmarks</string>
    <string name="nav_history">History</string>
    <string name="nav_settings">Settings</string>

    <!-- Shields -->
    <string name="shields_title">Shields</string>
    <string name="shields_blocked_on_page">%1$d trackers and ads blocked on this page</string>
    <string name="shields_nothing_blocked">Nothing blocked on this page yet</string>
    <string name="shields_toggle_label">Shields</string>
    <string name="shields_description">Blocking %1$d known ad/tracker domains. Applies everywhere for now — per-site control is next.</string>

    <!-- Common -->
    <string name="action_cancel">Cancel</string>
    <string name="action_confirm">Confirm</string>
    <string name="action_delete">Delete</string>
    <string name="action_close">Close</string>
    <string name="action_done">Done</string>
    <string name="action_send">Send</string>

    <!-- PDL AI -->
    <string name="pdl_ai_title">PDL AI</string>
    <string name="pdl_ai_empty_title">Ask PDL AI anything</string>
    <string name="pdl_ai_empty_body">The chat works right now — the model connection is the part still being built. See what you get today.</string>
    <string name="pdl_ai_input_hint">Message PDL AI</string>
    <string name="pdl_ai_typing">PDL AI is typing…</string>
    <string name="settings_pdl_ai">PDL AI</string>
    <string name="pdl_ai_api_key_label">API key</string>
    <string name="pdl_ai_api_key_hint">Not connected to a model yet — this is where a key will go</string>

    <!-- Feature stubs -->
    <string name="soon_badge">SOON</string>
    <string name="coming_soon_body">Not built yet — this is a placeholder so the app already looks and navigates like the finished thing. Check docs/ROADMAP.md for what\'s next.</string>
</resources>
SFEOF

echo '  writing app/src/main/AndroidManifest.xml'
cat > app/src/main/AndroidManifest.xml << 'SFEOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Phase 0: only what a WebView browser actually needs to load pages.
         Camera/location/storage/notifications get added, permission by
         permission, alongside the features that use them. -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <!-- Runtime-requested on API 33+ (see MainActivity). Covers both the
         system Download Manager's own progress notifications and Surf
         Fountain's own notifications once those exist. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name=".SurfFountainApplication"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.SurfFountain"
        android:enableOnBackInvokedCallback="true"
        android:networkSecurityConfig="@xml/network_security_config"
        android:supportsRtl="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|uiMode"
            android:theme="@style/Theme.SurfFountain.Starting">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- Let Surf Fountain offer itself as a target for shared/opened links. -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="http" />
                <data android:scheme="https" />
            </intent-filter>
        </activity>

    </application>

</manifest>
SFEOF

echo
echo "Done. 43 files written."
echo "Next:"
echo "  git add -A && git commit -m \"Brave-style UI overhaul + features\""
echo "  git push"
echo "  bash scripts/build.sh"
echo
echo "If you have NOT run scripts/create_keystore.sh yet, run that first —"
echo "CI now refuses to build unsigned on purpose (see docs/SIGNING.md)."
