package com.hedaya.android.ui.screens

import android.view.HapticFeedbackConstants
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import android.content.Context
import android.graphics.Typeface
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.Typeface as ComposeTypeface
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.MUQATTAAT_SURAHS
import hedaya.shared.QuranPage
import hedaya.shared.QuranPageSegment
import hedaya.shared.QuranSurah
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun QuranReaderScreen(
    pages: List<QuranPage>,
    surahs: List<QuranSurah>,
    initialPageIndex: Int,
    onPageChanged: (pageNumber: Int, surahNumber: Int, ayahNumber: Int) -> Unit,
    onMarkQuranDone: () -> Unit,
    onOpenSurahPicker: () -> Unit,
    onBack: () -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val scope = rememberCoroutineScope()
    val view = LocalView.current

    // RTL: page 0 = index (pages.size - 1) in pager, so we reverse
    val pagerState = rememberPagerState(
        initialPage = pages.size - 1 - initialPageIndex,
        pageCount = { pages.size }
    )

    var showChrome by remember { mutableStateOf(true) }

    // Current actual page (1-based Mushaf)
    val currentPageIndex = pages.size - 1 - pagerState.currentPage
    val currentPage = pages.getOrNull(currentPageIndex)
    val currentMushafPage = currentPage?.pageNumber ?: 1

    // Find surah name for current page
    val currentSurahName = currentPage?.segments?.lastOrNull()?.surahName ?: ""

    // Report page changes
    LaunchedEffect(Unit) {
        snapshotFlow { pagerState.currentPage }.collect { pagerIdx ->
            val pageIdx = pages.size - 1 - pagerIdx
            val page = pages.getOrNull(pageIdx)
            if (page != null) {
                val firstAyah = page.segments.firstOrNull()?.ayahs?.firstOrNull()
                onPageChanged(
                    page.pageNumber,
                    firstAyah?.surahNumber ?: 1,
                    firstAyah?.number ?: 1
                )
            }
        }
    }

    val backgroundColor = if (isDark) Color(0xFF1E1A14) else Color(0xFFFDFAF4)
    val textColor = if (isDark) Color(0xFFE8DCC8) else Color(0xFF2C3E50)

    Box(modifier = Modifier.fillMaxSize().background(backgroundColor)) {
        // Pager
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
            reverseLayout = true
        ) { pagerIdx ->
            val pageIdx = pages.size - 1 - pagerIdx
            val page = pages.getOrNull(pageIdx)
            if (page != null) {
                MushafPageContent(
                    page = page,
                    surahs = surahs,
                    textColor = textColor,
                    isDark = isDark,
                    onTapCenter = { showChrome = !showChrome }
                )
            }
        }

        // Top chrome
        AnimatedVisibility(
            visible = showChrome,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(backgroundColor.copy(alpha = 0.95f))
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Text("✕", fontSize = 18.sp, color = textColor)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        currentSurahName,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = HedayaColors.QuranGoldStart
                    )
                    Text(
                        "صفحة $currentMushafPage",
                        fontSize = 12.sp,
                        color = textColor.copy(alpha = 0.6f)
                    )
                }
                IconButton(onClick = onOpenSurahPicker) {
                    Text("☰", fontSize = 18.sp, color = textColor)
                }
            }
        }

        // Bottom chrome
        AnimatedVisibility(
            visible = showChrome,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(backgroundColor.copy(alpha = 0.95f))
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Next page (visually left in RTL)
                IconButton(
                    onClick = {
                        scope.launch {
                            if (pagerState.currentPage < pages.size - 1) {
                                pagerState.animateScrollToPage(pagerState.currentPage + 1)
                            }
                        }
                    },
                    enabled = pagerState.currentPage < pages.size - 1
                ) {
                    Text("→", fontSize = 18.sp, color = textColor.copy(alpha = if (pagerState.currentPage < pages.size - 1) 1f else 0.3f))
                }

                Text(
                    "صفحة $currentMushafPage من ${pages.size}",
                    fontSize = 13.sp,
                    color = textColor.copy(alpha = 0.6f)
                )

                // Ward completion button
                Button(
                    onClick = {
                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                        onMarkQuranDone()
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = HedayaColors.QuranGoldStart
                    ),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Text("✓ ورد", fontSize = 14.sp, color = Color.White)
                }

                // Prev page (visually right in RTL)
                IconButton(
                    onClick = {
                        scope.launch {
                            if (pagerState.currentPage > 0) {
                                pagerState.animateScrollToPage(pagerState.currentPage - 1)
                            }
                        }
                    },
                    enabled = pagerState.currentPage > 0
                ) {
                    Text("←", fontSize = 18.sp, color = textColor.copy(alpha = if (pagerState.currentPage > 0) 1f else 0.3f))
                }
            }
        }
    }
}

@Composable
private fun MushafPageContent(
    page: QuranPage,
    surahs: List<QuranSurah>,
    textColor: Color,
    isDark: Boolean,
    onTapCenter: () -> Unit
) {
    val goldColor = Color(0xFFB8860B)
    val context = LocalContext.current
    val amiriFont = remember {
        try {
            val typeface = Typeface.createFromAsset(context.assets, "fonts/AmiriQuran.ttf")
            FontFamily(androidx.compose.ui.text.font.Typeface(typeface))
        } catch (_: Exception) {
            FontFamily.Default
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) { onTapCenter() }
            .padding(top = 60.dp, bottom = 60.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            for (segment in page.segments) {
                // Surah header
                if (segment.showSurahHeader) {
                    SurahHeaderBanner(segment.surahName, goldColor, isDark)
                    Spacer(modifier = Modifier.height(8.dp))

                    // Basmala (not for Al-Fatiha=1 and At-Tawbah=9)
                    if (segment.surahNumber != 1 && segment.surahNumber != 9) {
                        Text(
                            "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
                            fontSize = 20.sp,
                            fontFamily = amiriFont,
                            color = textColor,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }

                // Al-Fatiha: verse-by-verse centered
                if (segment.surahNumber == 1) {
                    for (ayah in segment.ayahs) {
                        Text(
                            buildAnnotatedString {
                                append(ayah.text)
                                append(" ")
                                withStyle(SpanStyle(color = goldColor, fontSize = 16.sp)) {
                                    append("﴿${toArabicNumerals(ayah.number)}﴾")
                                }
                            },
                            fontSize = 24.sp,
                            fontFamily = amiriFont,
                            color = textColor,
                            textAlign = TextAlign.Center,
                            lineHeight = 42.sp,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                    }
                }
                // Muqattaat first ayah centered
                else if (segment.surahNumber in MUQATTAAT_SURAHS && segment.showSurahHeader && segment.ayahs.isNotEmpty()) {
                    val firstAyah = segment.ayahs.first()
                    Text(
                        buildAnnotatedString {
                            append(firstAyah.text)
                            append(" ")
                            withStyle(SpanStyle(color = goldColor, fontSize = 18.sp)) {
                                append("﴿${toArabicNumerals(firstAyah.number)}﴾")
                            }
                        },
                        fontSize = 26.sp,
                        fontFamily = amiriFont,
                        color = textColor,
                        textAlign = TextAlign.Center,
                        lineHeight = 46.sp,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    // Rest of ayahs as flowing text
                    if (segment.ayahs.size > 1) {
                        FlowingAyahText(
                            ayahs = segment.ayahs.drop(1),
                            textColor = textColor,
                            goldColor = goldColor,
                            fontFamily = amiriFont
                        )
                    }
                }
                // Normal flowing text
                else {
                    FlowingAyahText(
                        ayahs = segment.ayahs,
                        textColor = textColor,
                        goldColor = goldColor,
                        fontFamily = amiriFont
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun FlowingAyahText(
    ayahs: List<hedaya.shared.QuranAyah>,
    textColor: Color,
    goldColor: Color,
    fontFamily: FontFamily
) {
    val annotated = buildAnnotatedString {
        for (ayah in ayahs) {
            append(ayah.text)
            append(" ")
            withStyle(SpanStyle(color = goldColor, fontSize = 16.sp)) {
                append("﴿${toArabicNumerals(ayah.number)}﴾")
            }
            append(" ")
        }
    }

    Text(
        text = annotated,
        fontSize = 24.sp,
        fontFamily = fontFamily,
        color = textColor,
        textAlign = TextAlign.Center,
        lineHeight = 42.sp,
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
private fun SurahHeaderBanner(surahName: String, goldColor: Color, isDark: Boolean) {
    val bannerBg = if (isDark) goldColor.copy(alpha = 0.15f) else goldColor.copy(alpha = 0.1f)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(bannerBg)
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            surahName,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = goldColor
        )
    }
}

private fun toArabicNumerals(num: Int): String {
    val arabicDigits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
    return num.toString().map { arabicDigits[it - '0'] }.joinToString("")
}
