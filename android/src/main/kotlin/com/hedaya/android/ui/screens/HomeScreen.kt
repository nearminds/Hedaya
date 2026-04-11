package com.hedaya.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.AzkarGroup
import hedaya.shared.PathLevel
import hedaya.shared.PrayerDayLog
import hedaya.shared.PrayerName
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun HomeScreen(
    groups: List<AzkarGroup>,
    onGeneralSebhaClick: () -> Unit,
    onGroupClick: (AzkarGroup) -> Unit,
    onAppearanceClick: () -> Unit = {},
    onQuranClick: () -> Unit = {},
    onWorshipPathClick: () -> Unit = {},
    todayLog: PrayerDayLog = PrayerDayLog(),
    streakDays: Int = 0,
    currentLevel: PathLevel = PathLevel.seeds,
    nextPrayer: Pair<PrayerName, Date>? = null
) {
    val isDark = isSystemInDarkTheme()
    val dailyGroups = groups.take(2) // morning & evening
    val otherGroups = groups.drop(2)

    Box(modifier = Modifier.fillMaxSize().background(HedayaColors.backgroundGradient(isDark))) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Main scrollable content
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 80.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.weight(1f)
            ) {
                // Appearance toggle
                item(span = { GridItemSpan(2) }) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        horizontalArrangement = Arrangement.Start
                    ) {
                        IconButton(onClick = onAppearanceClick) {
                            Text("◐", fontSize = 22.sp, color = if (isDark) HedayaColors.HeaderTextDark else HedayaColors.PrimaryGreen)
                        }
                    }
                }

                // Header
                item(span = { GridItemSpan(2) }) {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text("\uFDFD", fontSize = 28.sp, color = if (isDark) HedayaColors.HeaderTextDark else Color(0xFF1B5E3A))
                        Text("هداية", fontSize = 34.sp, fontWeight = FontWeight.Bold, color = if (isDark) HedayaColors.PrimaryGreenDark else HedayaColors.PrimaryGreen)
                        Text("حَصِّن يومك بذكر الله", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                // Today Status Card
                item(span = { GridItemSpan(2) }) {
                    TodayStatusCard(
                        todayLog = todayLog,
                        streakDays = streakDays,
                        currentLevel = currentLevel,
                        nextPrayer = nextPrayer,
                        isDark = isDark,
                        onClick = onWorshipPathClick
                    )
                }

                // Section: وردك اليومي
                item(span = { GridItemSpan(2) }) {
                    SectionHeader(title = "وردك اليومي")
                }

                // Quran card (full width)
                item(span = { GridItemSpan(2) }) {
                    QuranCardComposable(isDone = todayLog.quranDone, onClick = onQuranClick)
                }

                // Morning & evening azkar
                items(dailyGroups) { group ->
                    GroupCard(group = group, onClick = { onGroupClick(group) })
                }

                // Section: أذكار وأدعية
                item(span = { GridItemSpan(2) }) {
                    SectionHeader(title = "أذكار وأدعية")
                }

                // Other groups (handle last odd item)
                itemsIndexed(otherGroups) { index, group ->
                    val isLastOdd = otherGroups.size % 2 == 1 && index == otherGroups.size - 1
                    if (!isLastOdd) {
                        GroupCard(group = group, onClick = { onGroupClick(group) })
                    }
                }
                if (otherGroups.size % 2 == 1) {
                    item(span = { GridItemSpan(2) }) {
                        GroupCard(group = otherGroups.last(), onClick = { onGroupClick(otherGroups.last()) })
                    }
                }

                // Section: أدوات
                item(span = { GridItemSpan(2) }) {
                    SectionHeader(title = "أدوات")
                }

                // General Sebha
                item(span = { GridItemSpan(2) }) {
                    GeneralSebhaCard(onClick = onGeneralSebhaClick)
                }
            }

            // Bottom bar
            HomeBottomBar(isDark = isDark, onClick = onWorshipPathClick)
        }
    }
}

@Composable
private fun TodayStatusCard(
    todayLog: PrayerDayLog,
    streakDays: Int,
    currentLevel: PathLevel,
    nextPrayer: Pair<PrayerName, Date>?,
    isDark: Boolean,
    onClick: () -> Unit
) {
    val hasContent = nextPrayer != null || streakDays > 0
    if (!hasContent) return

    val cardBg = if (isDark) HedayaColors.CardSurfaceDark else HedayaColors.CardSurfaceLight
    val timeFormat = remember { SimpleDateFormat("h:mm a", Locale("ar")) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(cardBg)
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (nextPrayer != null) {
                StatusRow(
                    label = "الصلاة القادمة",
                    value = "${nextPrayer.first.arabicName}  ${timeFormat.format(nextPrayer.second)}",
                    iconColor = HedayaColors.PrimaryGreenLight,
                    isDark = isDark
                )
            }
            if (streakDays > 0) {
                StatusRow(
                    label = "سلسلتك",
                    value = "$streakDays يوم · ${currentLevel.arabicName}",
                    iconColor = Color(0xFFE67E22),
                    isDark = isDark
                )
            }
        }
    }
}

@Composable
private fun StatusRow(label: String, value: String, iconColor: Color, isDark: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(label, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.width(6.dp))
            Box(
                modifier = Modifier.size(8.dp).clip(RoundedCornerShape(4.dp)).background(iconColor)
            )
        }
    }
}

@Composable
private fun QuranCardComposable(isDone: Boolean, onClick: () -> Unit) {
    val gradient = Brush.linearGradient(
        colors = listOf(HedayaColors.QuranGoldStart, HedayaColors.QuranGoldEnd)
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(8.dp, RoundedCornerShape(20.dp))
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .clickable(onClick = onClick)
            .padding(vertical = 24.dp, horizontal = 12.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(if (isDone) "📖" else "📖", fontSize = 28.sp)
            Text("القرآن الكريم", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Color.White, textAlign = TextAlign.Center)
            Text(
                if (isDone) "✓ تم الورد" else "اقرأ وردك اليوم",
                fontSize = 13.sp,
                color = Color.White.copy(alpha = 0.85f)
            )
        }
    }
}

@Composable
private fun HomeBottomBar(isDark: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (isDark) Color(0xFF0D1A14).copy(alpha = 0.9f) else Color.White.copy(alpha = 0.9f))
            .padding(horizontal = 20.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(22.dp))
                .background(HedayaColors.PrimaryGreen.copy(alpha = 0.12f))
                .clickable(onClick = onClick)
                .padding(horizontal = 18.dp, vertical = 12.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("🌿", fontSize = 16.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "مسيرتي",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = HedayaColors.PrimaryGreen
                )
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
        textAlign = TextAlign.End
    )
}

@Composable
private fun GeneralSebhaCard(onClick: () -> Unit) {
    CardWithGradient(
        gradient = Brush.linearGradient(listOf(HedayaColors.PrimaryGreen, HedayaColors.PrimaryGreenLight)),
        icon = "📿",
        title = "سبحة عامة",
        subtitle = "عدّاد ذكر",
        onClick = onClick
    )
}

@Composable
private fun GroupCard(group: AzkarGroup, onClick: () -> Unit) {
    val (start, end) = when (group.color) {
        "morning" -> HedayaColors.MorningStart to HedayaColors.MorningEnd
        "evening" -> HedayaColors.EveningStart to HedayaColors.EveningEnd
        "prayer" -> HedayaColors.PrayerStart to HedayaColors.PrayerEnd
        "sleep" -> HedayaColors.SleepStart to HedayaColors.SleepEnd
        "misc" -> HedayaColors.MiscStart to HedayaColors.MiscEnd
        "ad3ia" -> HedayaColors.Ad3iaStart to HedayaColors.Ad3iaEnd
        else -> HedayaColors.PrimaryGreen to HedayaColors.PrimaryGreenLight
    }
    val subtitle = if (group.tags.contains("Ad3ia")) "${group.azkar.size} أدعية" else "${group.azkar.size} أذكار"
    val iconEmoji = when (group.color) {
        "morning" -> "☀️"; "evening" -> "🌙"; "prayer" -> "🤲"
        "sleep" -> "🛏️"; "misc" -> "✨"; "ad3ia" -> "📿"; else -> "📖"
    }
    CardWithGradient(
        gradient = Brush.linearGradient(listOf(start, end)),
        icon = iconEmoji, title = group.name, subtitle = subtitle, onClick = onClick
    )
}

@Composable
private fun CardWithGradient(gradient: Brush, icon: String, title: String, subtitle: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(8.dp, RoundedCornerShape(20.dp))
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .clickable(onClick = onClick)
            .padding(vertical = 24.dp, horizontal = 12.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(icon, fontSize = 28.sp, color = Color.White.copy(alpha = 0.9f))
            Text(title, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Color.White, textAlign = TextAlign.Center)
            Text(subtitle, fontSize = 13.sp, color = Color.White.copy(alpha = 0.85f))
        }
    }
}
