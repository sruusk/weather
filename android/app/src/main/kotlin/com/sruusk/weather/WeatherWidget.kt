package com.sruusk.weather

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import androidx.glance.appwidget.cornerRadius

class WeatherWidget : GlanceAppWidget() {
    
    override val stateDefinition: GlanceStateDefinition<*> = HomeWidgetGlanceStateDefinition()
    
    // Support exact sizing for varied widget sizes across launchers
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // Get native app widget ID
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)

        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            GlanceContent(context, state, appWidgetId)
        }
    }

    private fun getIconResId(condition: String): Int {
        return when (condition) {
            "clear-day" -> R.drawable.ic_clear_day
            "partly-cloudy-day" -> R.drawable.ic_partly_cloudy_day
            "cloudy" -> R.drawable.ic_cloudy
            "overcast" -> R.drawable.ic_overcast
            "fog" -> R.drawable.ic_fog
            "drizzle" -> R.drawable.ic_drizzle
            "sleet" -> R.drawable.ic_sleet
            "rain" -> R.drawable.ic_rain
            "overcast-rain" -> R.drawable.ic_overcast_rain
            "extreme-rain" -> R.drawable.ic_extreme_rain
            "snow" -> R.drawable.ic_snow
            "overcast-snow" -> R.drawable.ic_overcast_snow
            "extreme-snow" -> R.drawable.ic_extreme_snow
            "thunderstorms" -> R.drawable.ic_thunderstorms
            "thunderstorms-extreme" -> R.drawable.ic_thunderstorms_extreme
            "partly-cloudy-day-rain" -> R.drawable.ic_partly_cloudy_day_rain
            "partly-cloudy-day-snow" -> R.drawable.ic_partly_cloudy_day_snow
            else -> R.drawable.ic_not_available
        }
    }

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState, appWidgetId: Int) {
        val prefs = state.preferences
        // Fallback to defaults if specific widget data is not yet available
        val temp = prefs.getString("temp_$appWidgetId", prefs.getString("temp", "--")) ?: "--"
        val condition = prefs.getString("condition_$appWidgetId", prefs.getString("condition", "")) ?: ""
        val location = prefs.getString("location_$appWidgetId", prefs.getString("location", "No Location")) ?: "No Location"
        val highLowRaw = prefs.getString("highLow_$appWidgetId", prefs.getString("highLow", "")) ?: ""
        val hourlyRaw = prefs.getString("hourly_$appWidgetId", prefs.getString("hourly", "")) ?: ""
        val dailyRaw = prefs.getString("daily_$appWidgetId", prefs.getString("daily", "")) ?: ""

        val highLowParts = highLowRaw.split("|")
        val highTemp = highLowParts.getOrNull(0) ?: ""
        val lowTemp = highLowParts.getOrNull(1) ?: ""

        val size = LocalSize.current
        val textColor = ColorProvider(Color.White)
        val mutedTextColor = ColorProvider(Color.LightGray)
        val dividerColor = ColorProvider(Color(0xFF333333))
        val bgColor = ColorProvider(Color(0xFF1E1E1E))
        
        Box(
            modifier = GlanceModifier.fillMaxSize().background(bgColor).cornerRadius(24.dp),
            contentAlignment = Alignment.Center
        ) {
            val isSmall = size.width < 120.dp
            val isShort = size.height < 130.dp

            if (isSmall) {
                // 1-column wide Widget
                Column(
                    modifier = GlanceModifier.fillMaxSize().padding(12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (condition.isNotEmpty()) {
                        Image(
                            provider = ImageProvider(getIconResId(condition)),
                            contentDescription = condition,
                            modifier = GlanceModifier.size(36.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(8.dp))
                    }
                    Text(
                        text = "$temp°", 
                        style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 24.sp),
                        maxLines = 1
                    )
                }
            } else if (isShort) {
                // Wide Layout (e.g., 2x1, 3x1, 4x1)
                Row(
                    modifier = GlanceModifier.fillMaxSize().padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Left Side: Current Weather
                    // Give it wrapContentWidth on 3x1/4x1 to steal space for hours, but defaultWeight on 2x1 to prevent crushing
                    val leftMod = if (size.width < 250.dp) {
                        GlanceModifier.fillMaxHeight().defaultWeight().padding(end = 8.dp)
                    } else {
                        GlanceModifier.fillMaxHeight().wrapContentWidth().padding(end = 16.dp)
                    }
                    Column(
                        modifier = leftMod,
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(text = location, style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 14.sp), maxLines = 1)
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (condition.isNotEmpty()) {
                                Image(provider = ImageProvider(getIconResId(condition)), contentDescription = condition, modifier = GlanceModifier.size(32.dp))
                                Spacer(modifier = GlanceModifier.width(6.dp))
                            }
                            Text(text = "$temp°", style = TextStyle(color = textColor, fontSize = 24.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                        }
                        if (highTemp.isNotEmpty() && lowTemp.isNotEmpty() && size.height >= 60.dp) {
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(text = "↑$highTemp ↓$lowTemp", style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                        }
                    }
                    
                    // Vertical Divider
                    Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().padding(vertical = 4.dp).background(dividerColor)) {}
                    
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    
                    // Right Side: Hourly Forecast
                    if (hourlyRaw.isNotEmpty()) {
                        val hours = hourlyRaw.split(",")
                        val maxHours = if (size.width >= 400.dp) 6 else if (size.width >= 320.dp) 5 else if (size.width >= 250.dp) 4 else if (size.width >= 200.dp) 3 else 2
                        Row(
                            modifier = GlanceModifier.fillMaxHeight().defaultWeight(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            val items = hours.take(maxHours)
                            items.forEachIndexed { index, hourData ->
                                val parts = hourData.split("|")
                                if (parts.size >= 3) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = GlanceModifier.defaultWeight()
                                    ) {
                                        Text(text = parts[0], style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Image(provider = ImageProvider(getIconResId(parts[1])), contentDescription = parts[1], modifier = GlanceModifier.size(22.dp))
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Text(text = parts[2], style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 14.sp), maxLines = 1)
                                    }
                                    if (index < items.size - 1) {
                                        Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().padding(vertical = 12.dp).background(dividerColor)) {}
                                    }
                                }
                            }
                        }
                    }
                }
            } else if (size.width < 250.dp) {
                // Stacked Layout (e.g., 2x2, 2x3)
                Column(
                    modifier = GlanceModifier.fillMaxSize().padding(vertical = 12.dp, horizontal = 12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Top: Current Weather
                    Column(
                        modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(text = location, style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 16.sp), maxLines = 1)
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (condition.isNotEmpty()) {
                                Image(provider = ImageProvider(getIconResId(condition)), contentDescription = condition, modifier = GlanceModifier.size(40.dp))
                                Spacer(modifier = GlanceModifier.width(8.dp))
                            }
                            Text(text = "$temp°", style = TextStyle(color = textColor, fontSize = 32.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                            if (highTemp.isNotEmpty() && lowTemp.isNotEmpty()) {
                                Spacer(modifier = GlanceModifier.width(12.dp))
                                Column(horizontalAlignment = Alignment.Start) {
                                    Text(text = "↑$highTemp", style = TextStyle(color = textColor, fontSize = 12.sp), maxLines = 1)
                                    Text(text = "↓$lowTemp", style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    
                    // Horizontal Divider
                    Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).padding(horizontal = 8.dp).background(dividerColor)) {}
                    
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    
                    // Bottom: Hourly Forecast
                    if (hourlyRaw.isNotEmpty()) {
                        val hours = hourlyRaw.split(",")
                        val maxHours = if (size.width < 160.dp) 3 else 4
                        Row(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            val items = hours.take(maxHours)
                            items.forEachIndexed { index, hourData ->
                                val parts = hourData.split("|")
                                if (parts.size >= 3) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = GlanceModifier.defaultWeight()
                                    ) {
                                        Text(text = parts[0], style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Image(provider = ImageProvider(getIconResId(parts[1])), contentDescription = parts[1], modifier = GlanceModifier.size(24.dp))
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Text(text = parts[2], style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 14.sp), maxLines = 1)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Large Layout (e.g., 3x2, 4x2)
                Column(
                    modifier = GlanceModifier.fillMaxSize().padding(vertical = 12.dp, horizontal = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Top Half: Current & Hourly
                    Row(
                        modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Left Side: Current Weather
                        Column(
                            modifier = GlanceModifier.fillMaxHeight().wrapContentWidth().padding(end = 12.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(text = location, style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 16.sp), maxLines = 1)
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                if (condition.isNotEmpty()) {
                                    Image(provider = ImageProvider(getIconResId(condition)), contentDescription = condition, modifier = GlanceModifier.size(36.dp))
                                    Spacer(modifier = GlanceModifier.width(8.dp))
                                }
                                Text(text = "$temp°", style = TextStyle(color = textColor, fontSize = 28.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                            }
                            if (highTemp.isNotEmpty() && lowTemp.isNotEmpty()) {
                                Spacer(modifier = GlanceModifier.height(2.dp))
                                Text(text = "↑$highTemp ↓$lowTemp", style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                            }
                        }
                        
                        // Vertical Divider
                        Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().padding(vertical = 2.dp).background(dividerColor)) {}
                        
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        
                        // Right Side: Hourly Forecast
                        if (hourlyRaw.isNotEmpty()) {
                            val hours = hourlyRaw.split(",")
                            val maxHours = if (size.width >= 400.dp) 6 else if (size.width >= 320.dp) 5 else 4
                            Row(
                                modifier = GlanceModifier.fillMaxHeight().defaultWeight(),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                val items = hours.take(maxHours)
                                items.forEachIndexed { index, hourData ->
                                    val parts = hourData.split("|")
                                    if (parts.size >= 3) {
                                        Column(
                                            horizontalAlignment = Alignment.CenterHorizontally,
                                            verticalAlignment = Alignment.CenterVertically,
                                            modifier = GlanceModifier.defaultWeight()
                                        ) {
                                            Text(text = parts[0], style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                                            Spacer(modifier = GlanceModifier.height(4.dp))
                                            Image(provider = ImageProvider(getIconResId(parts[1])), contentDescription = parts[1], modifier = GlanceModifier.size(24.dp))
                                            Spacer(modifier = GlanceModifier.height(4.dp))
                                            Text(text = parts[2], style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 12.sp), maxLines = 1)
                                        }
                                        if (index < items.size - 1) {
                                            Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().padding(vertical = 8.dp).background(dividerColor)) {}
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    
                    // Horizontal Divider
                    Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(dividerColor)) {}
                    
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    
                    // Bottom Half: Daily Forecast
                    if (dailyRaw.isNotEmpty()) {
                        val days = dailyRaw.split(",")
                        val maxDays = 5
                        Row(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            val items = days.take(maxDays)
                            items.forEachIndexed { index, dayData ->
                                val parts = dayData.split("|")
                                if (parts.size >= 4) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = GlanceModifier.defaultWeight()
                                    ) {
                                        Text(text = parts[0].uppercase(), style = TextStyle(color = textColor, fontSize = 12.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Image(provider = ImageProvider(getIconResId(parts[1])), contentDescription = parts[1], modifier = GlanceModifier.size(24.dp))
                                        Spacer(modifier = GlanceModifier.height(4.dp))
                                        Text(text = parts[2], style = TextStyle(color = textColor, fontWeight = FontWeight.Bold, fontSize = 14.sp), maxLines = 1)
                                        Text(text = parts[3], style = TextStyle(color = mutedTextColor, fontSize = 12.sp), maxLines = 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
