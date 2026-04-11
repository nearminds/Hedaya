package com.hedaya.android.ui.screens

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationCompat
import android.view.HapticFeedbackConstants
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.GOAL_PRESETS
import hedaya.shared.GOAL_RANGE_MAX
import hedaya.shared.GOAL_RANGE_MIN
import hedaya.shared.MAX_COUNTER_VALUE
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

private val Context.dataStore by preferencesDataStore(name = "hedaya_sebha")
private val KEY_COUNT = intPreferencesKey("sebha_count")
private val KEY_GOAL = intPreferencesKey("sebha_max_goal")

@Composable
fun GeneralSebhaScreen(onBack: () -> Unit) {
    val isDark = isSystemInDarkTheme()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var count by remember { mutableIntStateOf(runBlocking { context.dataStore.data.map { it[KEY_COUNT] ?: 0 }.first() }) }
    var maxGoal by remember { mutableIntStateOf(runBlocking { context.dataStore.data.map { it[KEY_GOAL] ?: 0 }.first() }) }
    var showSettings by remember { mutableStateOf(false) }
    var settingsGoal by remember { mutableIntStateOf(if (maxGoal > 0) maxGoal else 100) }
    val view = LocalView.current
    val effectiveGoal = if (maxGoal > 0) maxGoal else null
    val progress = if (effectiveGoal != null && effectiveGoal > 0) (count.toFloat() / effectiveGoal).coerceIn(0f, 1f) else 0f

    val cardBg = if (isDark) HedayaColors.CardSurfaceDark else HedayaColors.CardSurfaceLight
    val textPrimary = MaterialTheme.colorScheme.onSurface
    val textSecondary = MaterialTheme.colorScheme.onSurfaceVariant

    fun persist() {
        scope.launch {
            context.dataStore.edit { prefs ->
                prefs[KEY_COUNT] = count
                prefs[KEY_GOAL] = maxGoal
            }
        }
    }

    var hasNotifiedForGoal by remember { mutableStateOf(false) }
    LaunchedEffect(count, effectiveGoal) {
        if (effectiveGoal != null && count >= effectiveGoal && !hasNotifiedForGoal) {
            showNotification(context, count)
            hasNotifiedForGoal = true
        }
        if (count == 0) hasNotifiedForGoal = false
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(HedayaColors.backgroundGradient(isDark))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                IconButton(onClick = { showSettings = true }) {
                    Text("⚙️", fontSize = 22.sp)
                }
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "$count",
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                color = HedayaColors.PrimaryGreen
            )
            if (effectiveGoal != null) {
                Text("من $effectiveGoal", fontSize = 18.sp, color = textSecondary)
            } else {
                Text("اضغط للعد", fontSize = 16.sp, color = textSecondary)
            }
            if (effectiveGoal != null) {
                Spacer(modifier = Modifier.height(16.dp))
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(130.dp)
                ) {
                    androidx.compose.foundation.Canvas(modifier = Modifier.size(130.dp)) {
                        drawCircle(color = Color.Gray.copy(alpha = 0.15f), style = androidx.compose.ui.graphics.drawscope.Stroke(width = 6f))
                        drawArc(
                            color = HedayaColors.PrimaryGreen,
                            startAngle = 270f,
                            sweepAngle = 360f * progress,
                            useCenter = false,
                            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 6f, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(28.dp))
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(90.dp)
                    .clip(CircleShape)
                    .background(HedayaColors.PrimaryGreen.copy(alpha = 0.15f))
                    .clickable {
                        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                        if (count < MAX_COUNTER_VALUE) count++
                        persist()
                    }
            ) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(cardBg),
                    contentAlignment = Alignment.Center
                ) {
                    Text("👆", fontSize = 32.sp)
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = {
                view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                count = 0
                persist()
            }) {
                Text("إعادة الصفر")
            }
            Spacer(modifier = Modifier.weight(1f))
            IconButton(onClick = onBack) {
                Text("← رجوع", fontSize = 16.sp, color = textPrimary)
            }
        }
        if (showSettings) {
            SettingsSheet(
                isDark = isDark,
                goalEnabled = effectiveGoal != null,
                goalValue = settingsGoal,
                onGoalEnabledChange = { enabled ->
                    maxGoal = if (enabled) settingsGoal.coerceIn(GOAL_RANGE_MIN, GOAL_RANGE_MAX) else 0
                    persist()
                },
                onGoalValueChange = { settingsGoal = it },
                onDismiss = {
                    if (effectiveGoal != null) maxGoal = settingsGoal.coerceIn(GOAL_RANGE_MIN, GOAL_RANGE_MAX)
                    persist()
                    showSettings = false
                }
            )
        }
    }
}

@Composable
private fun SettingsSheet(
    isDark: Boolean,
    goalEnabled: Boolean,
    goalValue: Int,
    onGoalEnabledChange: (Boolean) -> Unit,
    onGoalValueChange: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetBg = if (isDark) HedayaColors.CardSurfaceDark else HedayaColors.CardSurfaceLight
    val textColor = MaterialTheme.colorScheme.onSurface

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f))
            .clickable(onClick = onDismiss)
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(sheetBg, RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
                .padding(24.dp)
                .clickable(enabled = false) {}
        ) {
            Text("إعدادات السبحة", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = textColor)
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("تفعيل هدف (إشعار عند الوصول)", color = textColor)
                Switch(
                    checked = goalEnabled,
                    onCheckedChange = onGoalEnabledChange
                )
            }
            if (goalEnabled) {
                Text("اختيار سريع", fontSize = 13.sp, color = Color.Gray)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    GOAL_PRESETS.forEach { preset ->
                        Button(
                            onClick = { onGoalValueChange(preset) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (goalValue == preset) HedayaColors.PrimaryGreen else HedayaColors.PrimaryGreen.copy(alpha = 0.15f)
                            )
                        ) {
                            Text("$preset")
                        }
                    }
                }
                Text("العدد: $goalValue", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = HedayaColors.PrimaryGreen)
                Slider(
                    value = goalValue.toFloat(),
                    onValueChange = { onGoalValueChange(it.toInt()) },
                    valueRange = GOAL_RANGE_MIN.toFloat()..GOAL_RANGE_MAX.toFloat(),
                    colors = SliderDefaults.colors(thumbColor = HedayaColors.PrimaryGreen, activeTrackColor = HedayaColors.PrimaryGreen)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text("تم")
            }
        }
    }
}

private fun showNotification(context: Context, count: Int) {
    val channelId = "sebha_goal"
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(channelId, "هدف السبحة", NotificationManager.IMPORTANCE_DEFAULT)
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
    }
    val notification = NotificationCompat.Builder(context, channelId)
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .setContentTitle("تم الوصول للهدف!")
        .setContentText("بلغت $count تسبيحة. بارك الله فيك.")
        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        .build()
    (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(1, notification)
}
