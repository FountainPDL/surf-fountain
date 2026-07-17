package com.surffountain.browser.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.surffountain.browser.data.local.dao.BookmarkDao
import com.surffountain.browser.data.local.dao.DownloadDao
import com.surffountain.browser.data.local.dao.HistoryDao
import com.surffountain.browser.data.local.dao.TabDao
import com.surffountain.browser.data.local.entity.BookmarkEntity
import com.surffountain.browser.data.local.entity.DownloadEntity
import com.surffountain.browser.data.local.entity.HistoryEntity
import com.surffountain.browser.data.local.entity.TabEntity

@Database(
    entities = [BookmarkEntity::class, HistoryEntity::class, TabEntity::class, DownloadEntity::class],
    version = 2,
    exportSchema = true
)
abstract class SurfFountainDatabase : RoomDatabase() {
    abstract fun bookmarkDao(): BookmarkDao
    abstract fun historyDao(): HistoryDao
    abstract fun tabDao(): TabDao
    abstract fun downloadDao(): DownloadDao

    companion object {
        const val DATABASE_NAME = "surf_fountain.db"
    }
}
