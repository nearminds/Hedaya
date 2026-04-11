package com.hedaya.android.ui.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.hedaya.android.data.QuranDataLoader
import hedaya.shared.QuranPage
import hedaya.shared.QuranSurah

class QuranViewModel(context: Context) : ViewModel() {
    val surahs: List<QuranSurah> = QuranDataLoader.allSurahs(context)
    val pages: List<QuranPage> = QuranDataLoader.allPages(context)

    fun pageIndexForSurah(surahNumber: Int): Int {
        val surah = surahs.firstOrNull { it.number == surahNumber } ?: return 0
        val firstPage = surah.ayahs.firstOrNull()?.page ?: 1
        return (firstPage - 1).coerceIn(0, pages.size - 1)
    }

    fun pageIndexForPage(pageNumber: Int): Int {
        return (pageNumber - 1).coerceIn(0, pages.size - 1)
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return QuranViewModel(context.applicationContext) as T
        }
    }
}
