package com.hedaya.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hedaya.android.ui.theme.HedayaColors
import com.hedaya.android.ui.viewmodel.PrayerTrackingViewModel
import hedaya.shared.PathLevel
import hedaya.shared.PrayerName

@Composable
fun WorshipPathScreen(
    trackingViewModel: PrayerTrackingViewModel,
    onBack: () -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val todayLog by trackingViewModel.todayLog.collectAsState()
    val streakDays by trackingViewModel.streakDays.collectAsState()
    val currentLevel by trackingViewModel.currentLevel.collectAsState()
    val levelProgress by trackingViewModel.levelProgress.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(HedayaColors.backgroundGradient(isDark))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Top bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Text("←", fontSize = 24.sp, color = MaterialTheme.colorScheme.onSurface)
                }
                Text(
                    "مسيرتي",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = HedayaColors.PrimaryGreen
                )
                Spacer(modifier = Modifier.size(48.dp))
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Level & streak card
            val cardBg = if (isDark) HedayaColors.CardSurfaceDark else HedayaColors.CardSurfaceLight
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(cardBg)
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Level icon
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                listOf(HedayaColors.PrimaryGreen, HedayaColors.PrimaryGreenLight)
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        when (currentLevel) {
                            PathLevel.seeds -> "🌱"
                            PathLevel.roots -> "🌿"
                            PathLevel.growth -> "🌳"
                            PathLevel.steadfast -> "💪"
                            PathLevel.blossom -> "🌸"
                        },
                        fontSize = 36.sp
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    currentLevel.arabicName,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    "$streakDays يوم متتالي",
                    fontSize = 15.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(12.dp))
                LinearProgressIndicator(
                    progress = { levelProgress.toFloat() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = HedayaColors.PrimaryGreenLight,
                    trackColor = Color.Gray.copy(alpha = 0.2f)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Daily prayers tracking
            Text(
                "صلوات اليوم",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            val prayers = listOf(
                PrayerName.fajr,
                PrayerName.dhuhr,
                PrayerName.asr,
                PrayerName.maghrib,
                PrayerName.isha
            )

            for (prayer in prayers) {
                val isDone = todayLog.prayersCompleted.contains(prayer)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(cardBg)
                        .clickable {
                            if (!isDone) trackingViewModel.markPrayerDone(prayer)
                        }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(
                                    if (isDone) HedayaColors.PrimaryGreenLight
                                    else Color.Gray.copy(alpha = 0.2f)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            if (isDone) {
                                Text("✓", fontSize = 14.sp, color = Color.White, fontWeight = FontWeight.Bold)
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            prayer.arabicName,
                            fontSize = 17.sp,
                            fontWeight = if (isDone) FontWeight.SemiBold else FontWeight.Normal,
                            color = if (isDone) HedayaColors.PrimaryGreen else MaterialTheme.colorScheme.onSurface
                        )
                    }
                    if (!isDone) {
                        Text(
                            "اضغط للتسجيل",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Quran ward
            val quranDone = todayLog.quranDone
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(cardBg)
                    .clickable {
                        if (!quranDone) trackingViewModel.markQuranDone()
                    }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(
                                if (quranDone) HedayaColors.QuranGoldStart
                                else Color.Gray.copy(alpha = 0.2f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        if (quranDone) {
                            Text("✓", fontSize = 14.sp, color = Color.White, fontWeight = FontWeight.Bold)
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        "ورد القرآن",
                        fontSize = 17.sp,
                        fontWeight = if (quranDone) FontWeight.SemiBold else FontWeight.Normal,
                        color = if (quranDone) HedayaColors.QuranGoldStart else MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Grace day button
            if (!todayLog.usedGraceDay && !todayLog.isOnPath()) {
                OutlinedButton(
                    onClick = { trackingViewModel.markGraceDay() },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("استخدام يوم رحمة", color = HedayaColors.PrimaryGreen)
                }
            }

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}
