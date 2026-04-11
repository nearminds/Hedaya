package com.hedaya.android.ui.viewmodel

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

private val Context.themeDataStore by preferencesDataStore(name = "hedaya_theme")
private val KEY_APPEARANCE = intPreferencesKey("appearance_mode")

/** 0 = auto (system), 1 = light, 2 = dark — matches iOS convention */
class ThemeViewModel(private val context: Context) : ViewModel() {

    val appearanceMode: StateFlow<Int> = context.themeDataStore.data
        .map { prefs -> prefs[KEY_APPEARANCE] ?: 0 }
        .stateIn(viewModelScope, SharingStarted.Eagerly, 0)

    fun setAppearanceMode(mode: Int) {
        viewModelScope.launch {
            context.themeDataStore.edit { prefs ->
                prefs[KEY_APPEARANCE] = mode
            }
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return ThemeViewModel(context.applicationContext) as T
        }
    }
}
