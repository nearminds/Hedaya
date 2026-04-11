package com.hedaya.android.ui.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.hedaya.android.data.PrayerTrackingRepository
import hedaya.shared.BranchType
import hedaya.shared.PathLevel
import hedaya.shared.PrayerDayLog
import hedaya.shared.PrayerName
import hedaya.shared.QuranReadingProgress
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.GregorianCalendar
import java.util.Locale
import java.util.TimeZone

class PrayerTrackingViewModel(context: Context) : ViewModel() {
    private val repo = PrayerTrackingRepository(context)
    private var dailyLogs: MutableMap<String, PrayerDayLog> = mutableMapOf()

    private val _todayLog = MutableStateFlow(PrayerDayLog(dateKey = dateKey()))
    val todayLog: StateFlow<PrayerDayLog> = _todayLog.asStateFlow()

    private val _streakDays = MutableStateFlow(0)
    val streakDays: StateFlow<Int> = _streakDays.asStateFlow()

    private val _currentLevel = MutableStateFlow(PathLevel.seeds)
    val currentLevel: StateFlow<PathLevel> = _currentLevel.asStateFlow()

    private val _levelProgress = MutableStateFlow(0.0)
    val levelProgress: StateFlow<Double> = _levelProgress.asStateFlow()

    private val _mercyDaysUsedThisWeek = MutableStateFlow(0)
    val mercyDaysUsedThisWeek: StateFlow<Int> = _mercyDaysUsedThisWeek.asStateFlow()

    private val _quranProgress = MutableStateFlow(QuranReadingProgress.initial)
    val quranProgress: StateFlow<QuranReadingProgress> = _quranProgress.asStateFlow()

    init {
        viewModelScope.launch {
            dailyLogs = repo.loadDailyLogs().toMutableMap()
            val key = dateKey()
            _todayLog.value = dailyLogs[key] ?: PrayerDayLog(dateKey = key)
            _quranProgress.value = repo.loadQuranProgress()
            refreshProgress()
        }
    }

    fun refreshTodayLog() {
        val key = dateKey()
        _todayLog.value = dailyLogs[key] ?: PrayerDayLog(dateKey = key)
    }

    private fun ensureTodayLogIsCurrent() {
        if (_todayLog.value.dateKey != dateKey()) {
            refreshTodayLog()
        }
    }

    fun markPrayerDone(prayer: PrayerName) {
        ensureTodayLogIsCurrent()
        val log = _todayLog.value.copy(
            prayersCompleted = _todayLog.value.prayersCompleted + prayer
        )
        updateAndSave(log)
    }

    fun markSunnahDone(prayer: PrayerName) {
        ensureTodayLogIsCurrent()
        val log = _todayLog.value.copy(
            sunnahCompleted = _todayLog.value.sunnahCompleted + prayer
        )
        updateAndSave(log)
    }

    fun markQuranDone() {
        ensureTodayLogIsCurrent()
        val log = _todayLog.value.copy(quranDone = true)
        updateAndSave(log)
    }

    fun markBranchDone(branch: BranchType) {
        ensureTodayLogIsCurrent()
        val log = _todayLog.value.copy(
            branchesCompleted = _todayLog.value.branchesCompleted + branch
        )
        updateAndSave(log)
    }

    fun markGraceDay() {
        ensureTodayLogIsCurrent()
        val log = _todayLog.value.copy(usedGraceDay = true)
        updateAndSave(log)
    }

    fun updateQuranProgress(pageNumber: Int, surahNumber: Int, ayahNumber: Int) {
        if (_quranProgress.value.lastPageNumber == pageNumber) return
        _quranProgress.value = QuranReadingProgress(
            lastSurahNumber = surahNumber,
            lastAyahNumber = ayahNumber,
            lastPageNumber = pageNumber
        )
        viewModelScope.launch { repo.saveQuranProgress(_quranProgress.value) }
    }

    private fun updateAndSave(log: PrayerDayLog) {
        _todayLog.value = log
        dailyLogs[log.dateKey] = log
        viewModelScope.launch {
            repo.saveDailyLogs(dailyLogs)
        }
        refreshProgress()
    }

    private fun refreshProgress() {
        val cal = gregorianCalendar()
        val weekStart = startOfWeekKey(cal.time)

        // Count mercy days this week
        var mercyUsed = 0
        for ((key, log) in dailyLogs) {
            if (log.usedGraceDay) {
                val logDate = parseDate(key) ?: continue
                if (startOfWeekKey(logDate) == weekStart) mercyUsed++
            }
        }
        _mercyDaysUsedThisWeek.value = mercyUsed

        // Calculate streak
        var streak = 0
        var check = Date()
        for (i in 0 until 365) {
            val key = dateKey(check)
            if (isOnPath(key)) {
                streak++
            } else {
                break
            }
            val c = gregorianCalendar()
            c.time = check
            c.add(Calendar.DAY_OF_YEAR, -1)
            check = c.time
        }
        _streakDays.value = streak
        _currentLevel.value = PathLevel.forStreak(streak)
        _levelProgress.value = PathLevel.progressInLevel(streak)
    }

    private fun isOnPath(dateKey: String): Boolean {
        val log = dailyLogs[dateKey] ?: return false
        if (log.usedGraceDay) return true
        return log.prayersCompleted.isNotEmpty()
                || log.sunnahCompleted.isNotEmpty()
                || log.sunriseSunnahDone
                || log.quranDone
                || log.branchesCompleted.isNotEmpty()
    }

    companion object {
        private fun gregorianCalendar(): GregorianCalendar {
            return GregorianCalendar(TimeZone.getDefault(), Locale.US).apply {
                firstDayOfWeek = Calendar.SATURDAY
            }
        }

        fun dateKey(date: Date = Date()): String {
            val cal = gregorianCalendar()
            cal.time = date
            return String.format(
                Locale.US, "%04d-%02d-%02d",
                cal.get(Calendar.YEAR),
                cal.get(Calendar.MONTH) + 1,
                cal.get(Calendar.DAY_OF_MONTH)
            )
        }

        private fun parseDate(key: String): Date? {
            return try {
                val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                fmt.calendar = gregorianCalendar()
                fmt.parse(key)
            } catch (_: Exception) {
                null
            }
        }

        private fun startOfWeekKey(date: Date): String {
            val cal = gregorianCalendar()
            cal.time = date
            cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
            return dateKey(cal.time)
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PrayerTrackingViewModel(context.applicationContext) as T
        }
    }
}
