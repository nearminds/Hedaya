package com.hedaya.android.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.NavHostController
import hedaya.shared.AzkarGroup
import com.hedaya.android.ui.screens.AppearanceSettingsSheet
import com.hedaya.android.ui.screens.AzkarGroupScreen
import com.hedaya.android.ui.screens.GeneralSebhaScreen
import com.hedaya.android.ui.screens.HomeScreen
import com.hedaya.android.ui.screens.QuranListScreen
import com.hedaya.android.ui.screens.QuranReaderScreen
import com.hedaya.android.ui.screens.SurahPickerSheet
import com.hedaya.android.ui.screens.WorshipPathScreen
import com.hedaya.android.ui.viewmodel.PrayerTimesViewModel
import com.hedaya.android.ui.viewmodel.PrayerTrackingViewModel
import com.hedaya.android.ui.viewmodel.QuranViewModel
import kotlinx.coroutines.launch

@Composable
fun HedayaApp(
    groups: List<AzkarGroup>,
    navController: NavHostController,
    appearanceMode: Int = 0,
    onAppearanceModeChange: (Int) -> Unit = {}
) {
    val context = LocalContext.current
    var showAppearanceSettings by remember { mutableStateOf(false) }

    val prayerTimesViewModel: PrayerTimesViewModel = viewModel(
        factory = PrayerTimesViewModel.Factory(context)
    )
    val trackingViewModel: PrayerTrackingViewModel = viewModel(
        factory = PrayerTrackingViewModel.Factory(context)
    )
    val quranViewModel: QuranViewModel = viewModel(
        factory = QuranViewModel.Factory(context)
    )

    val todayLog by trackingViewModel.todayLog.collectAsState()
    val streakDays by trackingViewModel.streakDays.collectAsState()
    val currentLevel by trackingViewModel.currentLevel.collectAsState()
    val prayerTimes by prayerTimesViewModel.prayerTimes.collectAsState()
    val quranProgress by trackingViewModel.quranProgress.collectAsState()

    CompositionLocalProvider(
        LocalLayoutDirection provides LayoutDirection.Rtl
    ) {
        NavHost(
            navController = navController,
            startDestination = "home"
        ) {
            composable("home") {
                HomeScreen(
                    groups = groups,
                    onGeneralSebhaClick = { navController.navigate("sebha") },
                    onGroupClick = { group ->
                        val index = groups.indexOf(group)
                        navController.navigate("group/$index")
                    },
                    onAppearanceClick = { showAppearanceSettings = true },
                    onQuranClick = { navController.navigate("quran") },
                    onWorshipPathClick = { navController.navigate("worship-path") },
                    todayLog = todayLog,
                    streakDays = streakDays,
                    currentLevel = currentLevel,
                    nextPrayer = prayerTimesViewModel.nextPrayer()
                )
            }
            composable("sebha") {
                GeneralSebhaScreen(onBack = { navController.popBackStack() })
            }
            composable(
                route = "group/{index}",
                arguments = listOf(navArgument("index") { type = NavType.IntType })
            ) { backStackEntry ->
                val index = backStackEntry.arguments?.getInt("index") ?: 0
                val group = groups.getOrNull(index) ?: return@composable
                AzkarGroupScreen(
                    group = group,
                    onBack = { navController.popBackStack() }
                )
            }
            composable("quran") {
                QuranListScreen(
                    surahs = quranViewModel.surahs,
                    readingProgress = quranProgress,
                    onSurahClick = { surahNumber ->
                        val pageIndex = quranViewModel.pageIndexForSurah(surahNumber)
                        navController.navigate("quran-reader/$pageIndex")
                    },
                    onContinueReading = {
                        val pageIndex = quranViewModel.pageIndexForPage(quranProgress.lastPageNumber)
                        navController.navigate("quran-reader/$pageIndex")
                    },
                    onBack = { navController.popBackStack() }
                )
            }
            composable(
                route = "quran-reader/{pageIndex}",
                arguments = listOf(navArgument("pageIndex") { type = NavType.IntType })
            ) { backStackEntry ->
                val pageIndex = backStackEntry.arguments?.getInt("pageIndex") ?: 0
                var showSurahPicker by remember { mutableStateOf(false) }

                QuranReaderScreen(
                    pages = quranViewModel.pages,
                    surahs = quranViewModel.surahs,
                    initialPageIndex = pageIndex,
                    onPageChanged = { pageNumber, surahNumber, ayahNumber ->
                        trackingViewModel.updateQuranProgress(pageNumber, surahNumber, ayahNumber)
                    },
                    onMarkQuranDone = {
                        trackingViewModel.markQuranDone()
                    },
                    onOpenSurahPicker = { showSurahPicker = true },
                    onBack = { navController.popBackStack() }
                )

                if (showSurahPicker) {
                    SurahPickerSheet(
                        surahs = quranViewModel.surahs,
                        onSurahSelected = { surahNumber ->
                            showSurahPicker = false
                            val newPageIndex = quranViewModel.pageIndexForSurah(surahNumber)
                            navController.popBackStack()
                            navController.navigate("quran-reader/$newPageIndex")
                        },
                        onDismiss = { showSurahPicker = false }
                    )
                }
            }
            composable("worship-path") {
                WorshipPathScreen(
                    trackingViewModel = trackingViewModel,
                    onBack = { navController.popBackStack() }
                )
            }
        }

        if (showAppearanceSettings) {
            AppearanceSettingsSheet(
                currentMode = appearanceMode,
                onModeSelected = onAppearanceModeChange,
                onDismiss = { showAppearanceSettings = false }
            )
        }
    }
}
