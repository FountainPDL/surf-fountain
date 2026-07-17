package com.surffountain.browser.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * One row per page visit (not per URL) so "group by day" / visit-count
 * statistics in the History phase don't need a redesign — they're just a
 * different query over the same table.
 */
@Entity(tableName = "history")
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val url: String,
    val title: String,
    val visitedAt: Long = System.currentTimeMillis()
)
