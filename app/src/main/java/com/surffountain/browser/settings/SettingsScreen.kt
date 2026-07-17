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
