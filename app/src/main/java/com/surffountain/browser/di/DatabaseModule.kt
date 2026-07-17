package com.surffountain.browser.di

import android.content.Context
import androidx.room.Room
import com.surffountain.browser.data.local.SurfFountainDatabase
import com.surffountain.browser.data.local.dao.BookmarkDao
import com.surffountain.browser.data.local.dao.DownloadDao
import com.surffountain.browser.data.local.dao.HistoryDao
import com.surffountain.browser.data.local.dao.TabDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): SurfFountainDatabase =
        Room.databaseBuilder(
            context,
            SurfFountainDatabase::class.java,
            SurfFountainDatabase.DATABASE_NAME
        )
            // Schema is still moving during active development (this build
            // adds Downloads + bookmark notes) — destructive fallback wipes
            // local bookmarks/history/tabs ONCE on this specific update
            // rather than needing a hand-written Migration for every
            // schema tweak this early. Swap for real Migrations once
            // there's real user data worth preserving across upgrades.
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun provideBookmarkDao(database: SurfFountainDatabase): BookmarkDao = database.bookmarkDao()

    @Provides
    fun provideHistoryDao(database: SurfFountainDatabase): HistoryDao = database.historyDao()

    @Provides
    fun provideTabDao(database: SurfFountainDatabase): TabDao = database.tabDao()

    @Provides
    fun provideDownloadDao(database: SurfFountainDatabase): DownloadDao = database.downloadDao()
}
