package com.surffountain.browser

import android.app.Application
import android.app.DownloadManager
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.surffountain.browser.data.repository.DownloadRepository
import com.surffountain.browser.downloads.DownloadCompletionReceiver
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import javax.inject.Inject

/**
 * Application entry point. Annotated for Hilt so it generates the
 * top-level dependency container every [Module] in [di] hangs off of.
 *
 * The one thing it does beyond that: registers the download-completion
 * receiver for the app's whole process lifetime, so a download finishing
 * updates its Room record even if the user isn't on the Downloads screen
 * when it happens.
 */
@HiltAndroidApp
class SurfFountainApplication : Application() {

    @Inject
    lateinit var downloadRepository: DownloadRepository

    private val appScope = CoroutineScope(SupervisorJob())
    private var downloadReceiver: DownloadCompletionReceiver? = null

    override fun onCreate() {
        super.onCreate()
        val receiver = DownloadCompletionReceiver(downloadRepository, appScope)
        downloadReceiver = receiver
        ContextCompat.registerReceiver(
            this,
            receiver,
            IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onTerminate() {
        downloadReceiver?.let { unregisterReceiver(it) }
        appScope.cancel()
        super.onTerminate()
    }
}
