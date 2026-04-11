package hedaya.shared

import kotlinx.serialization.Serializable

// ── JSON deserialization DTOs ──

@Serializable
data class QuranSurahDTO(
    val number: Int,
    val name: String,
    val englishName: String = "",
    val numberOfAyahs: Int = 0,
    val revelationType: String = "",
    val ayahs: List<QuranAyahDTO> = emptyList()
)

@Serializable
data class QuranAyahDTO(
    val number: Int,
    val text: String,
    val page: Int = 1
)

// ── Domain models ──

data class QuranSurah(
    val number: Int,
    val name: String,
    val englishName: String,
    val ayahCount: Int,
    val revelationType: String,
    val ayahs: List<QuranAyah>
)

data class QuranAyah(
    val number: Int,
    val surahNumber: Int,
    val text: String,
    val page: Int
)

data class QuranPageSegment(
    val surahNumber: Int,
    val surahName: String,
    val showSurahHeader: Boolean,
    val ayahs: List<QuranAyah>
)

data class QuranPage(
    val pageNumber: Int,
    val segments: List<QuranPageSegment>
)

@Serializable
data class QuranReadingProgress(
    val lastSurahNumber: Int = 1,
    val lastAyahNumber: Int = 1,
    val lastPageNumber: Int = 1
) {
    companion object {
        val initial = QuranReadingProgress()
    }
}

// Muqattaat surahs (disconnected letters) — first ayah centered
val MUQATTAAT_SURAHS = setOf(
    2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20,
    26, 27, 28, 29, 30, 31, 32, 36, 38,
    40, 41, 42, 43, 44, 45, 46, 50, 68
)
