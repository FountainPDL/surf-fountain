package com.surffountain.browser.browser

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.surffountain.browser.R
import com.surffountain.browser.privacy.AdBlockEngine

/**
 * Reachable by tapping the badge in the address bar (see AddressBar.kt's
 * ShieldsBadge). v1: one global on/off switch + this page's block count.
 * Per-site allow-listing is the natural next step — AdBlockEngine.isBlocked
 * already accepts an allowlist parameter, nothing here is a dead end.
 */
@Composable
fun ShieldsPanel(
    siteHost: String,
    shieldsEnabled: Boolean,
    blockedCount: Int,
    onToggle: (Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.shields_title)) },
        text = {
            Column {
                if (siteHost.isNotBlank()) {
                    Text(
                        text = siteHost,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
                Text(
                    text = if (blockedCount > 0) {
                        stringResource(R.string.shields_blocked_on_page, blockedCount)
                    } else {
                        stringResource(R.string.shields_nothing_blocked)
                    },
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(stringResource(R.string.shields_toggle_label), style = MaterialTheme.typography.bodyLarge)
                    Switch(checked = shieldsEnabled, onCheckedChange = onToggle)
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = stringResource(R.string.shields_description, AdBlockEngine.blockedDomainCount),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_done)) }
        }
    )
}
