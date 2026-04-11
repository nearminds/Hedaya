package com.hedaya.android.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

data class Coordinate(val latitude: Double, val longitude: Double)

class PrayerLocationManager(private val context: Context) {
    private val fusedClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private val _coordinate = MutableStateFlow<Coordinate?>(null)
    val coordinate: StateFlow<Coordinate?> = _coordinate.asStateFlow()

    private val _locationDescription = MutableStateFlow<String?>(null)
    val locationDescription: StateFlow<String?> = _locationDescription.asStateFlow()

    fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    fun requestLocation() {
        if (!hasLocationPermission()) return

        // Get last known location first for quick result
        fusedClient.lastLocation.addOnSuccessListener { location ->
            location?.let { updateLocation(it) }
        }

        // Request a single fresh location
        val request = LocationRequest.Builder(Priority.PRIORITY_LOW_POWER, 60_000L)
            .setMaxUpdates(1)
            .build()

        fusedClient.requestLocationUpdates(request, object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { updateLocation(it) }
                fusedClient.removeLocationUpdates(this)
            }
        }, Looper.getMainLooper())
    }

    private fun updateLocation(location: Location) {
        val coord = Coordinate(location.latitude, location.longitude)
        _coordinate.value = coord
        reverseGeocode(coord)
    }

    @Suppress("DEPRECATION")
    private fun reverseGeocode(coord: Coordinate) {
        try {
            val geocoder = Geocoder(context, Locale("ar"))
            val addresses = geocoder.getFromLocation(coord.latitude, coord.longitude, 1)
            if (!addresses.isNullOrEmpty()) {
                val addr = addresses[0]
                val parts = listOfNotNull(addr.locality, addr.adminArea, addr.countryName)
                _locationDescription.value = parts.joinToString("، ")
            }
        } catch (_: Exception) {
            // Geocoding may fail — location still works
        }
    }
}
