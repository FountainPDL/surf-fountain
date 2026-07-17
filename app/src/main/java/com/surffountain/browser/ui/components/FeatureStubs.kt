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
