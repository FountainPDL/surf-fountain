package com.surffountain.browser.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val FountainDarkScheme = darkColorScheme(
    primary = FountainPurpleLight,
    onPrimary = PureBlack,
    primaryContainer = FountainVioletContainer,
    onPrimaryContainer = FountainPurpleLight,
    secondary = FountainPurple,
    onSecondary = PureBlack,
    tertiary = FountainRedLight,
    onTertiary = PureBlack,
    tertiaryContainer = FountainRedDark,
    onTertiaryContainer = FountainRedLight,
    background = PureBlack,
    onBackground = PureWhite,
    surface = NearBlackSurface,
    onSurface = PureWhite,
    surfaceVariant = NearBlackSurfaceElevated,
    onSurfaceVariant = PureWhite,
    error = DangerRed
)

private val FountainLightScheme = lightColorScheme(
    primary = FountainPurpleDark,
    onPrimary = PureWhite,
    primaryContainer = FountainPurpleLight,
    onPrimaryContainer = FountainVioletContainer,
    secondary = FountainPurple,
    onSecondary = PureWhite,
    tertiary = FountainRedDark,
    onTertiary = PureWhite,
    tertiaryContainer = FountainRedLight,
    onTertiaryContainer = FountainRedDark,
    background = PureWhite,
    onBackground = PureBlack,
    surface = OffWhiteSurface,
    onSurface = PureBlack,
    surfaceVariant = FountainPurpleLight,
    onSurfaceVariant = FountainVioletContainer,
    error = DangerRed
)

/**
 * @param darkTheme resolved light/dark boolean — callers translate the
 *   user's SYSTEM/LIGHT/DARK preference (see AppTheme) into this before
 *   calling in, so this composable itself stays a dumb, testable function
 *   of a single boolean.
 * @param dynamicColor Material You wallpaper-derived color, Android 12+.
 *   Falls back to the brand purple palette below that, or if the user has
 *   disabled it — same convention Android's own reference apps use.
 */
@Composable
fun SurfFountainTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        darkTheme -> FountainDarkScheme
        else -> FountainLightScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = SurfFountainTypography,
        content = content
    )
}
