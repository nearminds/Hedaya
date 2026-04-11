package com.hedaya.android.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hedaya.android.ui.theme.HedayaColors
import hedaya.shared.QuranSurah

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SurahPickerSheet(
    surahs: List<QuranSurah>,
    onSurahSelected: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var searchQuery by remember { mutableStateOf("") }
    val filtered = if (searchQuery.isBlank()) surahs
    else surahs.filter { it.name.contains(searchQuery) || it.englishName.contains(searchQuery, ignoreCase = true) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            Text(
                "اختر سورة",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = HedayaColors.QuranGoldStart,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("بحث...") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            LazyColumn(modifier = Modifier.padding(top = 8.dp)) {
                items(filtered) { surah ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSurahSelected(surah.number) }
                            .padding(vertical = 12.dp, horizontal = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "${surah.number}",
                            fontSize = 14.sp,
                            color = HedayaColors.QuranGoldStart,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            surah.name,
                            fontSize = 17.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            surah.englishName,
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
