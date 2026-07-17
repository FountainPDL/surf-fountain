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
