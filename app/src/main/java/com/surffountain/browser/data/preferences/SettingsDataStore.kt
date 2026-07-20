package com.surffountain.browser.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "surf_fountain_settings")

enum class AppTheme { SYSTEM, LIGHT, DARK }

/**
 * Small, flat key-value settings. FountainSurf (the in-house search
 * provider) needs a live backend and isn't built yet, so the default
 * search/home engine here is a real, working one rather than a
 * placeholder URL that goes nowhere. The Search phase adds a proper
 * multi-engine picker; this key is where it plugs in.
 *
 * Every write goes through withContext(NonCancellable): these are all
 * launched from viewModelScope.launch { ... } call sites, and a
 * ViewModel's scope gets cancelled the moment its screen is popped —
 * which happens easily and fast (pick a setting, immediately tap back).
 * Without NonCancellable, a write racing that cancellation silently never
 * reaches disk. That was the actual cause of "search engine choice doesn't
 * take effect" — not a logic bug in the read/write itself.
 */
@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val HOME_PAGE_URL = stringPreferencesKey("home_page_url")
        val SEARCH_TEMPLATE = stringPreferencesKey("search_template")
        val SHIELDS_ENABLED = booleanPreferencesKey("shields_enabled")
        val TOTAL_BLOCKED_COUNT = longPreferencesKey("total_blocked_count")
        val PDL_AI_API_KEY = stringPreferencesKey("pdl_ai_api_key")
    }

    val theme: Flow<AppTheme> = context.dataStore.data.map { prefs ->
        when (prefs[Keys.THEME]) {
            "LIGHT" -> AppTheme.LIGHT
            "DARK" -> AppTheme.DARK
            else -> AppTheme.SYSTEM
        }
    }

    /** What a new tab, and the toolbar Home button, navigate to. Defaults
     *  to the native New-Tab page rather than an external URL — the same
     *  default every mainstream mobile browser ships with. */
    val homePageUrl: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.HOME_PAGE_URL] ?: HOME_SENTINEL
    }

    /** URL template (containing a literal "%s") used to turn a typed or
     *  home-screen search query into a URL. Google by default; becomes a
     *  full multi-engine picker in Settings > Search engine. */
    val searchTemplate: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.SEARCH_TEMPLATE] ?: DEFAULT_SEARCH_TEMPLATE
    }

    /** Shields — ad/tracker blocking. On by default, in keeping with
     *  "Private" being half the app's tagline. */
    val shieldsEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.SHIELDS_ENABLED] ?: true
    }

    suspend fun setShieldsEnabled(enabled: Boolean) = writeNonCancellable {
        context.dataStore.edit { it[Keys.SHIELDS_ENABLED] = enabled }
    }

    /** All-time blocked count, for the New Tab Privacy Stats widget.
     *  BrowserViewModel flushes each page's live count in here as that
     *  page is navigated away from or its tab closes — see its kdoc. */
    val totalBlockedCount: Flow<Long> = context.dataStore.data.map { prefs ->
        prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
    }

    suspend fun addToBlockedCount(delta: Long) {
        if (delta <= 0) return
        writeNonCancellable {
            context.dataStore.edit { prefs ->
                val current = prefs[Keys.TOTAL_BLOCKED_COUNT] ?: 0L
                prefs[Keys.TOTAL_BLOCKED_COUNT] = current + delta
            }
        }
    }

    /** Stored in plain DataStore for now, not Android Keystore-encrypted —
     *  fine for local development, not where this should stay once PDL AI
     *  actually makes calls with it. Flagged here on purpose rather than
     *  quietly left as a surprise. */
    val pdlAiApiKey: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.PDL_AI_API_KEY] ?: ""
    }

    suspend fun setPdlAiApiKey(key: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.PDL_AI_API_KEY] = key }
    }

    suspend fun setTheme(theme: AppTheme) = writeNonCancellable {
        context.dataStore.edit { it[Keys.THEME] = theme.name }
    }

    suspend fun setHomePageUrl(url: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.HOME_PAGE_URL] = url }
    }

    suspend fun setSearchTemplate(template: String) = writeNonCancellable {
        context.dataStore.edit { it[Keys.SEARCH_TEMPLATE] = template }
    }

    private suspend fun writeNonCancellable(block: suspend () -> Unit) {
        withContext(NonCancellable) { block() }
    }

    companion object {
        /** Not a real network scheme — recognized by BrowserScreen to mean
         *  "render the native Home composable instead of a WebView". */
        const val HOME_SENTINEL = "surf://home"
        const val DEFAULT_SEARCH_TEMPLATE = "https://www.google.com/search?q=%s"
    }
}
