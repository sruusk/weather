package com.sruusk.weather

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class WeatherWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WeatherWidget>() {
    override val glanceAppWidget = WeatherWidget()
}
