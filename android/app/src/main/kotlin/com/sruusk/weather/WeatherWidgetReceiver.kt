package com.sruusk.weather

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class WeatherWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WeatherWidget>() {
    override val glanceAppWidget = WeatherWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val triggeredFromHomeWidget = intent.getBooleanExtra("triggeredFromHomeWidget", false)
            
            // Only trigger Dart background update if it was an OS native update!
            // If it was triggered by Flutter (HomeWidget.updateWidget), do NOT trigger again to avoid infinite loop.
            if (!triggeredFromHomeWidget) {
                val backgroundIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java)
                backgroundIntent.action = "es.antonborri.home_widget.action.BACKGROUND"
                context.sendBroadcast(backgroundIntent)
            }
        }
    }
}
