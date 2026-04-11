package com.hedaya.android.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// ── Light palette ──
private val Primary = Color(0xFF1B7A4A)
private val PrimaryVariant = Color(0xFF2ECC71)
private val OnPrimary = Color.White
private val SurfaceLight = Color(0xFFF0F7F4)
private val OnSurfaceLight = Color(0xFF2C3E50)

// ── Dark palette ──
private val SurfaceDark = Color(0xFF0D1A14)
private val OnSurfaceDark = Color(0xFFE0E8E4)
private val PrimaryDark = Color(0xFF4CAF82)

private val LightColorScheme = lightColorScheme(
    primary = Primary,
    onPrimary = OnPrimary,
    surface = SurfaceLight,
    onSurface = OnSurfaceLight,
    surfaceVariant = Color(0xFFE8F5E9),
    onSurfaceVariant = Color(0xFF2D4A3E)
)

private val DarkColorScheme = darkColorScheme(
    primary = PrimaryDark,
    onPrimary = Color.White,
    surface = SurfaceDark,
    onSurface = OnSurfaceDark,
    surfaceVariant = Color(0xFF1A2E24),
    onSurfaceVariant = Color(0xFFA8C4B8)
)

/**
 * @param appearanceMode 0 = auto, 1 = light, 2 = dark (matches iOS convention)
 */
@Composable
fun HedayaTheme(
    appearanceMode: Int = 0,
    content: @Composable () -> Unit
) {
    val isDark = when (appearanceMode) {
        1 -> false
        2 -> true
        else -> isSystemInDarkTheme()
    }
    val colorScheme = if (isDark) DarkColorScheme else LightColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).setAppearanceLightStatusBars(!isDark)
        }
    }
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

object HedayaColors {
    val PrimaryGreen = Color(0xFF1B7A4A)
    val PrimaryGreenLight = Color(0xFF2ECC71)

    // Dark mode header gradient
    val PrimaryGreenDark = Color(0xFF4CAF82)
    val PrimaryGreenLightDark = Color(0xFF7ED957)
    val HeaderTextDark = Color(0xFF5EC98A)

    // Group gradients (same in both modes — cards already have white text)
    val MorningStart = Color(0xFFF39C12)
    val MorningEnd = Color(0xFFF1C40F)
    val EveningStart = Color(0xFF2C3E50)
    val EveningEnd = Color(0xFF3498DB)
    val PrayerStart = Color(0xFF1B7A4A)
    val PrayerEnd = Color(0xFF2ECC71)
    val SleepStart = Color(0xFF8E44AD)
    val SleepEnd = Color(0xFF9B59B6)
    val MiscStart = Color(0xFFE74C3C)
    val MiscEnd = Color(0xFFE67E22)
    val Ad3iaStart = Color(0xFF0D7377)
    val Ad3iaEnd = Color(0xFF14A3B8)
    val TextSecondary = Color(0xFF2D4A3E)

    // Quran card
    val QuranGoldStart = Color(0xFF8B6914)
    val QuranGoldEnd = Color(0xFFD4A017)

    // Background gradients
    val LightBackgroundColors = listOf(Color(0xFFF0F7F4), Color(0xFFE8F5E9), Color(0xFFF5F5F5))
    val DarkBackgroundColors = listOf(Color(0xFF0D1A14), Color(0xFF0A1510), Color(0xFF0F1410))

    fun backgroundGradient(isDark: Boolean): Brush = Brush.verticalGradient(
        if (isDark) DarkBackgroundColors else LightBackgroundColors
    )

    // Card surface in dark mode
    val CardSurfaceLight = Color.White
    val CardSurfaceDark = Color(0xFF1A2E24)
}
