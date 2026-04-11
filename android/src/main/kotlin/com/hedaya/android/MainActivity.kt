package com.hedaya.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.rememberNavController
import com.hedaya.android.ui.HedayaApp
import com.hedaya.android.ui.theme.HedayaTheme
import com.hedaya.android.ui.viewmodel.ThemeViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val themeViewModel: ThemeViewModel = viewModel(
                factory = ThemeViewModel.Factory(applicationContext)
            )
            val appearanceMode by themeViewModel.appearanceMode.collectAsState()

            HedayaTheme(appearanceMode = appearanceMode) {
                val context = LocalContext.current
                val groups = remember { loadGroupsFromAssets(context) }
                val navController = rememberNavController()
                Surface(modifier = Modifier.fillMaxSize()) {
                    HedayaApp(
                        groups = groups,
                        navController = navController,
                        appearanceMode = appearanceMode,
                        onAppearanceModeChange = { themeViewModel.setAppearanceMode(it) }
                    )
                }
            }
        }
    }
}
