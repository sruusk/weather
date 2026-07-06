package com.sruusk.weather

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class WeatherWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WeatherWidget>() {
    override val glanceAppWidget = WeatherWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        // Trigger Dart background update when Android natively requests a widget update
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java)
        intent.action = "es.antonborri.home_widget.action.BACKGROUND"
        context.sendBroadcast(intent)
    }
}
