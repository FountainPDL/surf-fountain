package com.surffountain.browser.ui.theme

import androidx.compose.ui.graphics.Brush

/** The New Tab page background — purple to red/orange, the same general
 *  diagonal-gradient language a lot of privacy-forward browsers use for
 *  their start page, rendered in Surf Fountain's own palette rather than
 *  anyone else's exact values. */
val FountainNewTabGradient = Brush.linearGradient(
    colors = listOf(FountainVioletContainer, FountainPurpleDark, FountainOrange, FountainRedDark)
)
