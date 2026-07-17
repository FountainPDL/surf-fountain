package com.surffountain.browser.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * The persisted "what tabs were open" list, restored on cold start.
 *
 * Known Phase 0 limitation, by design rather than oversight: this stores
 * url/title/position, not the WebView navigation-history Bundle. A tab
 * restored after the app process has actually died reloads fresh at its
 * last URL rather than resuming its exact back-stack/scroll position.
 * Within a live process (screen rotation, switching apps, low-memory
 * reclaim short of a full kill) full state is preserved because the
 * WebView instance itself stays alive — see BrowserViewModel.
 */
@Entity(tableName = "tabs")
data class TabEntity(
    @PrimaryKey
    val id: String,
    val url: String,
    val title: String,
    val position: Int,
    val isPrivate: Boolean = false,
    val lastAccessedAt: Long = System.currentTimeMillis()
)
