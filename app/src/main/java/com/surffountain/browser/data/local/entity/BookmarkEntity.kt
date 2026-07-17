package com.surffountain.browser.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * A saved page. [folder] is nullable and unused by any UI yet — it exists
 * now so the Bookmarks phase (folders, tags, sort) can land as a pure
 * additive change instead of a schema migration.
 */
@Entity(
    tableName = "bookmarks",
    indices = [Index(value = ["url"], unique = true)]
)
data class BookmarkEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val url: String,
    val title: String,
    val folder: String? = null,
    /** Surf Fountain exclusive: a private note attached to a saved page —
     *  "use this account", "check back for restock", etc. Not a Brave
     *  feature; see docs/ROADMAP.md. */
    val note: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
