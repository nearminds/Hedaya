package com.hedaya.android.notifications

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.hedaya.android.ui.viewmodel.PrayerTimesTodayAndroid
import hedaya.shared.PrayerName
import java.util.Date

class AzanNotificationManager {
    companion object {
        private const val CHANNEL_ID = "hedaya_azan"
        private const val CHANNEL_NAME = "أذان الصلاة"

        fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "إشعارات أوقات الصلاة"
                }
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.createNotificationChannel(channel)
            }
        }

        fun scheduleNotifications(context: Context, prayerTimes: PrayerTimesTodayAndroid?) {
            cancelAll(context)
            if (prayerTimes == null) return

            createChannel(context)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val now = Date()

            val prayers = listOf(
                PrayerName.fajr to prayerTimes.fajr,
                PrayerName.dhuhr to prayerTimes.dhuhr,
                PrayerName.asr to prayerTimes.asr,
                PrayerName.maghrib to prayerTimes.maghrib,
                PrayerName.isha to prayerTimes.isha
            )

            for ((index, pair) in prayers.withIndex()) {
                val (prayer, time) = pair
                if (time.before(now)) continue

                val intent = Intent(context, AzanBroadcastReceiver::class.java).apply {
                    putExtra("prayer_name", prayer.arabicName)
                    putExtra("notification_id", index + 100)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    index + 100,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                time.time,
                                pendingIntent
                            )
                        } else {
                            alarmManager.setAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                time.time,
                                pendingIntent
                            )
                        }
                    } else {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            time.time,
                            pendingIntent
                        )
                    }
                } catch (_: SecurityException) {
                    // Fall back to inexact alarm
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        time.time,
                        pendingIntent
                    )
                }
            }
        }

        private fun cancelAll(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            for (i in 100..104) {
                val intent = Intent(context, AzanBroadcastReceiver::class.java)
                val pendingIntent = PendingIntent.getBroadcast(
                    context, i, intent,
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                )
                pendingIntent?.let { alarmManager.cancel(it) }
            }
        }
    }
}

class AzanBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayer_name") ?: "الصلاة"
        val notificationId = intent.getIntExtra("notification_id", 0)

        AzanNotificationManager.createChannel(context)

        val notification = NotificationCompat.Builder(context, "hedaya_azan")
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode_off)
            .setContentTitle("حان وقت صلاة $prayerName")
            .setContentText("حيّ على الصلاة")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }
}
