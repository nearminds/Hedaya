package hedaya.shared

import kotlinx.serialization.Serializable

@Serializable
enum class PrayerName(val arabicName: String) {
    fajr("الفجر"),
    dhuhr("الظهر"),
    asr("العصر"),
    maghrib("المغرب"),
    isha("العشاء");
}

@Serializable
enum class BranchType(val arabicName: String) {
    sunnahPrayer("صلاة سنة"),
    sadaqa("صدقة"),
    morningZikr("أذكار الصباح"),
    sleepingZikr("أذكار النوم"),
    eveningZikr("أذكار المساء"),
    extraDuaa("دعاء إضافي"),
    extraZikr("ذكر إضافي"),
    extraSalah("صلاة إضافية");
}

@Serializable
enum class PrayerCalculationMethod(val arabicName: String) {
    muslimWorldLeague("رابطة العالم الإسلامي"),
    egyptian("الهيئة المصرية"),
    northAmerica("أمريكا الشمالية"),
    ummAlQura("أم القرى"),
    karachi("كراتشي"),
    turkey("تركيا");
}

@Serializable
data class PrayerDayLog(
    val dateKey: String = "",
    val prayersCompleted: Set<PrayerName> = emptySet(),
    val sunnahCompleted: Set<PrayerName> = emptySet(),
    val sunriseSunnahDone: Boolean = false,
    val quranDone: Boolean = false,
    val branchesCompleted: Set<BranchType> = emptySet(),
    val usedGraceDay: Boolean = false
) {
    /** A day counts as "on path" if Quran done + at least 3 prayers, or grace day used */
    fun isOnPath(): Boolean {
        if (usedGraceDay) return true
        return quranDone && prayersCompleted.size >= 3
    }
}

@Serializable
enum class PathLevel(val arabicName: String, val milestone: Int) {
    seeds("بذور", 0),
    roots("جذور", 7),
    growth("نموّ", 14),
    steadfast("ثبات", 21),
    blossom("إزهار", 28);

    companion object {
        fun forStreak(days: Int): PathLevel = entries.lastOrNull { days >= it.milestone } ?: seeds

        fun progressInLevel(days: Int): Double {
            val level = forStreak(days)
            val nextIndex = entries.indexOf(level) + 1
            if (nextIndex >= entries.size) return 1.0
            val next = entries[nextIndex]
            val range = next.milestone - level.milestone
            return if (range > 0) ((days - level.milestone).toDouble() / range).coerceIn(0.0, 1.0) else 1.0
        }
    }
}
