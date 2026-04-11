package com.hedaya.android.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import hedaya.shared.PrayerCalculationMethod
import hedaya.shared.PrayerDayLog
import hedaya.shared.QuranReadingProgress
import hedaya.shared.WorshipProfile
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.trackingDataStore by preferencesDataStore(name = "hedaya_tracking")

private val KEY_DAILY_LOGS = stringPreferencesKey("daily_logs")
private val KEY_CALCULATION_METHOD = stringPreferencesKey("calculation_method")
private val KEY_QURAN_PROGRESS = stringPreferencesKey("quran_progress")
private val KEY_WORSHIP_PROFILE = stringPreferencesKey("worship_profile")

private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

class PrayerTrackingRepository(private val context: Context) {

    suspend fun loadDailyLogs(): Map<String, PrayerDayLog> {
        val raw = context.trackingDataStore.data.map { it[KEY_DAILY_LOGS] }.first()
        if (raw.isNullOrBlank()) return emptyMap()
        return try {
            json.decodeFromString<Map<String, PrayerDayLog>>(raw)
        } catch (_: Exception) {
            emptyMap()
        }
    }

    suspend fun saveDailyLogs(logs: Map<String, PrayerDayLog>) {
        val encoded = json.encodeToString(logs)
        context.trackingDataStore.edit { it[KEY_DAILY_LOGS] = encoded }
    }

    suspend fun loadCalculationMethod(): PrayerCalculationMethod {
        val raw = context.trackingDataStore.data.map { it[KEY_CALCULATION_METHOD] }.first()
        return raw?.let {
            try { json.decodeFromString<PrayerCalculationMethod>(it) } catch (_: Exception) { null }
        } ?: PrayerCalculationMethod.ummAlQura
    }

    suspend fun saveCalculationMethod(method: PrayerCalculationMethod) {
        context.trackingDataStore.edit { it[KEY_CALCULATION_METHOD] = json.encodeToString(method) }
    }

    suspend fun loadQuranProgress(): QuranReadingProgress {
        val raw = context.trackingDataStore.data.map { it[KEY_QURAN_PROGRESS] }.first()
        if (raw.isNullOrBlank()) return QuranReadingProgress.initial
        return try {
            json.decodeFromString<QuranReadingProgress>(raw)
        } catch (_: Exception) {
            QuranReadingProgress.initial
        }
    }

    suspend fun saveQuranProgress(progress: QuranReadingProgress) {
        context.trackingDataStore.edit { it[KEY_QURAN_PROGRESS] = json.encodeToString(progress) }
    }

    suspend fun loadWorshipProfile(): WorshipProfile? {
        val raw = context.trackingDataStore.data.map { it[KEY_WORSHIP_PROFILE] }.first()
        if (raw.isNullOrBlank()) return null
        return try {
            json.decodeFromString<WorshipProfile>(raw)
        } catch (_: Exception) {
            null
        }
    }

    suspend fun saveWorshipProfile(profile: WorshipProfile) {
        context.trackingDataStore.edit { it[KEY_WORSHIP_PROFILE] = json.encodeToString(profile) }
    }
}
