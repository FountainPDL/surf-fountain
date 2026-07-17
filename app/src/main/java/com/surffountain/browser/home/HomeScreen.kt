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
