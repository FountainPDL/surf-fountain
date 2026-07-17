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
