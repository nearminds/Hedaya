package com.hedaya.android.data

import android.content.Context
import hedaya.shared.QuranAyah
import hedaya.shared.QuranAyahDTO
import hedaya.shared.QuranPage
import hedaya.shared.QuranPageSegment
import hedaya.shared.QuranSurah
import hedaya.shared.QuranSurahDTO
import kotlinx.serialization.json.Json

private val json = Json { ignoreUnknownKeys = true }

object QuranDataLoader {
    private var cachedSurahs: List<QuranSurah>? = null
    private var cachedPages: List<QuranPage>? = null

    fun allSurahs(context: Context): List<QuranSurah> {
        cachedSurahs?.let { return it }
        val loaded = loadSurahs(context)
        cachedSurahs = loaded
        return loaded
    }

    fun allPages(context: Context): List<QuranPage> {
        cachedPages?.let { return it }
        val pages = buildPages(allSurahs(context))
        cachedPages = pages
        return pages
    }

    /** 0-based index for a 1-based Mushaf page number */
    fun pageIndexForPage(page: Int, context: Context): Int {
        return (page - 1).coerceIn(0, allPages(context).size - 1)
    }

    /** 0-based index where the given surah begins */
    fun pageIndexForSurah(surahNumber: Int, context: Context): Int {
        val surah = allSurahs(context).firstOrNull { it.number == surahNumber } ?: return 0
        val firstPage = surah.ayahs.firstOrNull()?.page ?: 1
        return pageIndexForPage(firstPage, context)
    }

    private fun loadSurahs(context: Context): List<QuranSurah> {
        return try {
            val jsonStr = context.assets.open("data/quran.json").bufferedReader().use { it.readText() }
            val dtos = json.decodeFromString<List<QuranSurahDTO>>(jsonStr)
            dtos.map { dto ->
                QuranSurah(
                    number = dto.number,
                    name = dto.name,
                    englishName = dto.englishName,
                    ayahCount = dto.numberOfAyahs,
                    revelationType = dto.revelationType,
                    ayahs = dto.ayahs.map { ayahDto ->
                        QuranAyah(
                            number = ayahDto.number,
                            surahNumber = dto.number,
                            text = ayahDto.text,
                            page = ayahDto.page
                        )
                    }
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun buildPages(surahs: List<QuranSurah>): List<QuranPage> {
        val surahByNumber = surahs.associateBy { it.number }
        val allAyahs = surahs.flatMap { it.ayahs }
        val byPage = allAyahs.groupBy { it.page }

        return byPage.keys.sorted().map { pageNum ->
            val sorted = byPage[pageNum]!!.sortedWith(compareBy({ it.surahNumber }, { it.number }))

            val segments = mutableListOf<QuranPageSegment>()
            var groupSurah: Int? = null
            var groupAyahs = mutableListOf<QuranAyah>()

            fun flush() {
                val s = groupSurah ?: return
                if (groupAyahs.isEmpty()) return
                val surah = surahByNumber[s] ?: return
                val isStart = groupAyahs.first().number == 1
                segments.add(
                    QuranPageSegment(
                        surahNumber = s,
                        surahName = surah.name,
                        showSurahHeader = isStart,
                        ayahs = groupAyahs.toList()
                    )
                )
            }

            for (ayah in sorted) {
                if (ayah.surahNumber != groupSurah) {
                    flush()
                    groupSurah = ayah.surahNumber
                    groupAyahs = mutableListOf()
                }
                groupAyahs.add(ayah)
            }
            flush()

            QuranPage(pageNumber = pageNum, segments = segments)
        }
    }
}
