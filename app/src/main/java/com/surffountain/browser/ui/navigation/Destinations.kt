package com.surffountain.browser.ui.navigation

sealed class Destination(val route: String) {
    data object Browser : Destination("browser")
    data object Bookmarks : Destination("bookmarks")
    data object History : Destination("history")
    data object Settings : Destination("settings")
    data object PdlAi : Destination("pdl_ai")
    data object Downloads : Destination("downloads")
    data object About : Destination("about")
    data object SearchEngine : Destination("search_engine")
}
