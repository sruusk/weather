package com.sruusk.weather

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class WidgetConfigureActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        setResult(Activity.RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val favLocationsStr = flutterPrefs.getString("flutter.favouriteLocations", "") ?: ""
        
        val parsedLocations = parseLocations(favLocationsStr)
        val locations = mutableListOf("current_location")
        locations.addAll(parsedLocations)

        setContent {
            val isDarkTheme = isSystemInDarkTheme()
            val colors = if (isDarkTheme) darkColorScheme() else lightColorScheme()
            
            MaterialTheme(colorScheme = colors) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .systemBarsPadding(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Choose Location",
                            style = MaterialTheme.typography.headlineMedium.copy(
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onBackground
                            ),
                            modifier = Modifier.padding(bottom = 16.dp, top = 8.dp)
                        )
                        
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(locations) { location ->
                                LocationItem(location = location) {
                                    onLocationSelected(location)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    fun LocationItem(location: String, onClick: () -> Unit) {
        val name = extractLocationName(location)
        val isCurrentLocation = location == "current_location"
        
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onClick() },
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(
                containerColor = if (isCurrentLocation) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = name,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = if (isCurrentLocation) FontWeight.Bold else FontWeight.Normal,
                        color = if (isCurrentLocation) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }
        }
    }

    private fun extractLocationName(locationData: String): String {
        if (locationData == "current_location") {
            return "Current Location"
        }
        try {
            val parts = locationData.split("|")
            if (parts.size >= 3) {
                return parts[2] // The name field
            }
            return locationData
        } catch (e: Exception) {
            return locationData
        }
    }

    private fun parseLocations(data: String): List<String> {
        if (data.isEmpty()) return emptyList()
        return data.split(",").filter { it.isNotBlank() }
    }

    private fun onLocationSelected(locationData: String) {
        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("widget_${appWidgetId}_location", locationData).apply()
        
        val activeWidgetsStr = prefs.getString("active_widgets", "") ?: ""
        val activeWidgets = if (activeWidgetsStr.isEmpty()) mutableListOf() else activeWidgetsStr.split(",").toMutableList()
        if (!activeWidgets.contains(appWidgetId.toString())) {
            activeWidgets.add(appWidgetId.toString())
            prefs.edit().putString("active_widgets", activeWidgets.joinToString(",")).apply()
        }

        val bgIntent = Intent(this, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
        }
        sendBroadcast(bgIntent)
        
        val updateIntent = Intent(this, WeatherWidgetReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }
        sendBroadcast(updateIntent)

        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(Activity.RESULT_OK, resultValue)
        finish()
    }
}
