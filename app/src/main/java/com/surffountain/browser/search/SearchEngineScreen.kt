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
