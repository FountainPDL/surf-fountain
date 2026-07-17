package com.surffountain.browser.ui.navigation

import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.surffountain.browser.about.AboutScreen
import com.surffountain.browser.bookmarks.BookmarksScreen
import com.surffountain.browser.browser.BrowserScreen
import com.surffountain.browser.browser.BrowserViewModel
import com.surffountain.browser.downloads.DownloadsScreen
import com.surffountain.browser.history.HistoryScreen
import com.surffountain.browser.pdlai.PdlAiScreen
import com.surffountain.browser.search.SearchEngineScreen
import com.surffountain.browser.settings.SettingsScreen

/**
 * BrowserViewModel is requested once, here, at the graph's top level rather
 * than inside the "browser" composable() block — hiltViewModel() resolves
 * against the nearest ViewModelStoreOwner in the composition, which at
 * this point is the hosting Activity, giving one BrowserViewModel (and
 * therefore one live tab set) shared across every destination. Bookmarks/
 * History only get an onOpenUrl callback, not the ViewModel itself, so
 * they stay decoupled and easy to test on their own.
 */
@Composable
fun SurfFountainNavGraph(navController: NavHostController = rememberNavController()) {
    val browserViewModel: BrowserViewModel = hiltViewModel()

    NavHost(navController = navController, startDestination = Destination.Browser.route) {
        composable(Destination.Browser.route) {
            BrowserScreen(
                viewModel = browserViewModel,
                onNavigateToBookmarks = { navController.navigate(Destination.Bookmarks.route) },
                onNavigateToHistory = { navController.navigate(Destination.History.route) },
                onNavigateToSettings = { navController.navigate(Destination.Settings.route) },
                onNavigateToPdlAi = { navController.navigate(Destination.PdlAi.route) },
                onNavigateToDownloads = { navController.navigate(Destination.Downloads.route) }
            )
        }
        composable(Destination.Bookmarks.route) {
            BookmarksScreen(
                onBack = { navController.popBackStack() },
                onOpenUrl = { url ->
                    browserViewModel.navigateActiveTabTo(url)
                    navController.popBackStack(Destination.Browser.route, inclusive = false)
                }
            )
        }
        composable(Destination.History.route) {
            HistoryScreen(
                onBack = { navController.popBackStack() },
                onOpenUrl = { url ->
                    browserViewModel.navigateActiveTabTo(url)
                    navController.popBackStack(Destination.Browser.route, inclusive = false)
                }
            )
        }
        composable(Destination.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onNavigateToSearchEngine = { navController.navigate(Destination.SearchEngine.route) },
                onNavigateToAbout = { navController.navigate(Destination.About.route) },
                onNavigateToBookmarks = { navController.navigate(Destination.Bookmarks.route) }
            )
        }
        composable(Destination.SearchEngine.route) {
            SearchEngineScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.About.route) {
            AboutScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.PdlAi.route) {
            PdlAiScreen(onBack = { navController.popBackStack() })
        }
        composable(Destination.Downloads.route) {
            DownloadsScreen(onBack = { navController.popBackStack() })
        }
    }
}
