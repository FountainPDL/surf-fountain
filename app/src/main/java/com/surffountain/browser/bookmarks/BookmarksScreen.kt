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
