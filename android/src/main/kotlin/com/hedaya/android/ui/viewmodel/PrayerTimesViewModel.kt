package com.hedaya.android.ui.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.CalculationParameters
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import com.hedaya.android.location.Coordinate
import com.hedaya.android.location.PrayerLocationManager
import hedaya.shared.PrayerCalculationMethod
import hedaya.shared.PrayerName
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date
import java.util.GregorianCalendar

data class PrayerTimesTodayAndroid(
    val fajr: Date,
    val sunrise: Date,
    val dhuhr: Date,
    val asr: Date,
    val maghrib: Date,
    val isha: Date
) {
    fun time(prayer: PrayerName): Date = when (prayer) {
        PrayerName.fajr -> fajr
        PrayerName.dhuhr -> dhuhr
        PrayerName.asr -> asr
        PrayerName.maghrib -> maghrib
        PrayerName.isha -> isha
    }
}

class PrayerTimesViewModel(context: Context) : ViewModel() {

    val locationManager = PrayerLocationManager(context)

    private val _calculationMethod = MutableStateFlow(PrayerCalculationMethod.ummAlQura)
    val calculationMethod: StateFlow<PrayerCalculationMethod> = _calculationMethod.asStateFlow()

    val prayerTimes: StateFlow<PrayerTimesTodayAndroid?> = combine(
        locationManager.coordinate,
        _calculationMethod
    ) { coord, method ->
        coord?.let { computePrayerTimes(it, method) }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val locationDescription: StateFlow<String?> = locationManager.locationDescription

    fun setCalculationMethod(method: PrayerCalculationMethod) {
        _calculationMethod.value = method
    }

    fun requestLocation() {
        locationManager.requestLocation()
    }

    fun nextPrayer(): Pair<PrayerName, Date>? {
        val times = prayerTimes.value ?: return null
        val now = Date()
        val prayers = listOf(
            PrayerName.fajr to times.fajr,
            PrayerName.dhuhr to times.dhuhr,
            PrayerName.asr to times.asr,
            PrayerName.maghrib to times.maghrib,
            PrayerName.isha to times.isha
        )
        return prayers.firstOrNull { it.second.after(now) }
    }

    private fun computePrayerTimes(
        coord: Coordinate,
        method: PrayerCalculationMethod
    ): PrayerTimesTodayAndroid {
        val coordinates = Coordinates(coord.latitude, coord.longitude)
        val params: CalculationParameters = when (method) {
            PrayerCalculationMethod.muslimWorldLeague -> CalculationMethod.MUSLIM_WORLD_LEAGUE.parameters
            PrayerCalculationMethod.egyptian -> CalculationMethod.EGYPTIAN.parameters
            PrayerCalculationMethod.northAmerica -> CalculationMethod.NORTH_AMERICA.parameters
            PrayerCalculationMethod.ummAlQura -> CalculationMethod.UMM_AL_QURA.parameters
            PrayerCalculationMethod.karachi -> CalculationMethod.KARACHI.parameters
            PrayerCalculationMethod.turkey -> {
                // Turkey Diyanet: Fajr 18, Isha 17
                val p = CalculationMethod.OTHER.parameters
                p.fajrAngle = 18.0
                p.ishaAngle = 17.0
                p.madhab = Madhab.HANAFI
                p
            }
        }

        val cal = GregorianCalendar()
        val dateComponents = DateComponents(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH)
        )

        val prayerTimes = PrayerTimes(coordinates, dateComponents, params)
        return PrayerTimesTodayAndroid(
            fajr = prayerTimes.fajr,
            sunrise = prayerTimes.sunrise,
            dhuhr = prayerTimes.dhuhr,
            asr = prayerTimes.asr,
            maghrib = prayerTimes.maghrib,
            isha = prayerTimes.isha
        )
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PrayerTimesViewModel(context.applicationContext) as T
        }
    }
}
