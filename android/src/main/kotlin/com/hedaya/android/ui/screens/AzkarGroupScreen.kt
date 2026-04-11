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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.view.HapticFeedbackConstants
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.AzkarGroup

@Composable
fun AzkarGroupScreen(
    group: AzkarGroup,
    onBack: () -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val (start, end) = when (group.color) {
        "morning" -> HedayaColors.MorningStart to HedayaColors.MorningEnd
        "evening" -> HedayaColors.EveningStart to HedayaColors.EveningEnd
        "prayer" -> HedayaColors.PrayerStart to HedayaColors.PrayerEnd
        "sleep" -> HedayaColors.SleepStart to HedayaColors.SleepEnd
        "misc" -> HedayaColors.MiscStart to HedayaColors.MiscEnd
        "ad3ia" -> HedayaColors.Ad3iaStart to HedayaColors.Ad3iaEnd
        else -> HedayaColors.PrimaryGreen to HedayaColors.PrimaryGreenLight
    }
    val gradientColors = listOf(start, end)
    var currentIndex by remember { mutableIntStateOf(0) }
    var currentCount by remember { mutableIntStateOf(0) }
    var isCompleted by remember { mutableStateOf(false) }
    var showPulse by remember { mutableStateOf(false) }
    var showCompletionEffect by remember { mutableStateOf(false) }
    val view = LocalView.current

    val currentZikr = group.azkar.getOrNull(currentIndex) ?: return
    val progress = if (currentZikr.repetitions > 0) currentCount.toFloat() / currentZikr.repetitions else 0f
    val overallProgress = if (group.azkar.isNotEmpty()) (currentIndex.toFloat() + progress) / group.azkar.size else 0f

    val cardBg = if (isDark) HedayaColors.CardSurfaceDark else HedayaColors.CardSurfaceLight
    val textPrimary = MaterialTheme.colorScheme.onSurface
    val textSecondary = MaterialTheme.colorScheme.onSurfaceVariant

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(HedayaColors.backgroundGradient(isDark))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Text("←", fontSize = 24.sp, color = textPrimary)
                }
                Text(
                    text = group.name,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = start
                )
                Spacer(modifier = Modifier.size(48.dp))
            }
            if (isCompleted) {
                CompletionView(
                    groupName = group.name,
                    gradientColors = gradientColors,
                    textPrimary = textPrimary,
                    textSecondary = textSecondary,
                    onReset = {
                        currentIndex = 0
                        currentCount = 0
                        isCompleted = false
                        showCompletionEffect = false
                    },
                    onHome = onBack
                )
            } else {
                Text(
                    "الذكر ${currentIndex + 1} من ${group.azkar.size}",
                    fontSize = 13.sp,
                    color = textSecondary
                )
                Spacer(modifier = Modifier.height(6.dp))
                LinearProgressIndicator(
                    progress = { overallProgress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = start,
                    trackColor = Color.Gray.copy(alpha = 0.2f)
                )
                Spacer(modifier = Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .shadow(12.dp, RoundedCornerShape(24.dp))
                        .clip(RoundedCornerShape(24.dp))
                        .background(cardBg)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(20.dp)
                    ) {
                        Text(
                            text = currentZikr.text,
                            fontSize = 24.sp,
                            color = textPrimary,
                            textAlign = TextAlign.Center,
                            lineHeight = 36.sp
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = currentZikr.reference,
                            fontSize = 14.sp,
                            color = textSecondary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "$currentCount",
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                        color = start
                    )
                    Text(" / ", fontSize = 28.sp, color = textSecondary)
                    Text(
                        text = "${currentZikr.repetitions}",
                        fontSize = 28.sp,
                        color = textSecondary
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(120.dp)
                        .align(Alignment.CenterHorizontally)
                        .clickable {
                            view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                            showPulse = true
                            currentCount++
                            if (currentCount >= currentZikr.repetitions) {
                                view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                if (currentIndex < group.azkar.size - 1) {
                                    currentIndex++
                                    currentCount = 0
                                } else {
                                    isCompleted = true
                                    showCompletionEffect = true
                                }
                            }
                        }
                ) {
                    androidx.compose.foundation.Canvas(modifier = Modifier.size(120.dp)) {
                        drawCircle(color = Color.Gray.copy(alpha = 0.15f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = 6f))
                        drawArc(
                            color = gradientColors[0],
                            startAngle = 270f,
                            sweepAngle = 360f * progress,
                            useCenter = false,
                            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 6f, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                        )
                    }
                    Box(
                        modifier = Modifier
                            .size(90.dp)
                            .shadow(8.dp, CircleShape)
                            .clip(CircleShape)
                            .background(cardBg),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("👆", fontSize = 28.sp)
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = {
                            if (currentIndex > 0) {
                                currentIndex--
                                currentCount = 0
                            }
                        },
                        enabled = currentIndex > 0,
                        colors = ButtonDefaults.buttonColors(disabledContentColor = Color.Gray.copy(alpha = 0.4f))
                    ) {
                        Text("السابق")
                    }
                    Button(
                        onClick = {
                            if (currentIndex < group.azkar.size - 1) {
                                currentIndex++
                                currentCount = 0
                            }
                        },
                        enabled = currentIndex < group.azkar.size - 1,
                        colors = ButtonDefaults.buttonColors(disabledContentColor = Color.Gray.copy(alpha = 0.4f))
                    ) {
                        Text("التالي")
                    }
                }
            }
        }
    }
}

@Composable
private fun CompletionView(
    groupName: String,
    gradientColors: List<Color>,
    textPrimary: Color,
    textSecondary: Color,
    onReset: () -> Unit,
    onHome: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(modifier = Modifier.weight(1f))
        Box(
            modifier = Modifier
                .size(120.dp)
                .shadow(16.dp, CircleShape)
                .clip(CircleShape)
                .background(Brush.linearGradient(gradientColors)),
            contentAlignment = Alignment.Center
        ) {
            Text("✓", fontSize = 50.sp, color = Color.White, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(24.dp))
        Text("بارك الله فيك!", fontSize = 32.sp, fontWeight = FontWeight.Bold, color = textPrimary)
        Text("لقد أتممت $groupName", fontSize = 18.sp, color = textSecondary)
        Text("تقبّل الله منّا ومنكم", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = gradientColors[0])
        Spacer(modifier = Modifier.weight(1f))
        Button(onClick = onReset) {
            Text("إعادة")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Button(onClick = onHome, colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent, contentColor = gradientColors[0])) {
            Text("العودة للرئيسية")
        }
        Spacer(modifier = Modifier.height(40.dp))
    }
}
