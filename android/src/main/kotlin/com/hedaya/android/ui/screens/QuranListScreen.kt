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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.QuranReadingProgress
import hedaya.shared.QuranSurah

@Composable
fun QuranListScreen(
    surahs: List<QuranSurah>,
    readingProgress: QuranReadingProgress,
    onSurahClick: (Int) -> Unit,
    onContinueReading: () -> Unit,
    onBack: () -> Unit
) {
    val isDark = isSystemInDarkTheme()
    var searchQuery by remember { mutableStateOf("") }
    val filteredSurahs = if (searchQuery.isBlank()) surahs
    else surahs.filter { it.name.contains(searchQuery) || it.englishName.contains(searchQuery, ignoreCase = true) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(HedayaColors.backgroundGradient(isDark))
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Text("✕", fontSize = 20.sp, color = MaterialTheme.colorScheme.onSurface)
                }
                Text(
                    "القرآن الكريم",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = HedayaColors.QuranGoldStart
                )
                Spacer(modifier = Modifier.size(48.dp))
            }

            // Continue reading banner
            if (readingProgress.lastPageNumber > 1) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(HedayaColors.QuranGoldStart.copy(alpha = 0.15f))
                        .clickable { onContinueReading() }
                        .padding(14.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column {
                            Text(
                                "متابعة القراءة",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = HedayaColors.QuranGoldStart
                            )
                            Text(
                                "صفحة ${readingProgress.lastPageNumber}",
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Text("←", fontSize = 18.sp, color = HedayaColors.QuranGoldStart)
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Search
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                placeholder = { Text("بحث عن سورة...") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))

            // Surah list
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(filteredSurahs) { surah ->
                    SurahRow(
                        surah = surah,
                        onClick = { onSurahClick(surah.number) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SurahRow(surah: QuranSurah, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Surah number badge
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(HedayaColors.QuranGoldStart.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                "${surah.number}",
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = HedayaColors.QuranGoldStart
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                surah.name,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                "${surah.ayahCount} آيات · ${if (surah.revelationType == "Meccan") "مكية" else "مدنية"}",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            surah.englishName,
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Start
        )
    }
}
