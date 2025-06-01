import 'package:flutter/material.dart';
import 'package:weather/l10n/app_localizations.g.dart';

import '../widgets/weather_symbol_widget.dart';

class WeatherSymbolsPage extends StatefulWidget {
  const WeatherSymbolsPage({super.key});

  @override
  State<WeatherSymbolsPage> createState() => _WeatherSymbolsPageState();
}

class _WeatherSymbolsPageState extends State<WeatherSymbolsPage> with AutomaticKeepAliveClientMixin<WeatherSymbolsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(localizations.weatherSymbolsPageTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  children: [
                    _symbolCard(context, 'clear-day', localizations.clearDay,
                        localizations.clearDayDesc),
                    _symbolCard(context, 'clear-night',
                        localizations.clearNight, localizations.clearNightDesc),
                    _symbolCard(
                        context,
                        'partly-cloudy-day',
                        localizations.partlyCloudyDay,
                        localizations.partlyCloudyDayDesc),
                    _symbolCard(
                        context,
                        'partly-cloudy-night',
                        localizations.partlyCloudyNight,
                        localizations.partlyCloudyNightDesc),
                    _symbolCard(context, 'cloudy', localizations.cloudy,
                        localizations.cloudyDesc),
                    _symbolCard(context, 'rain', localizations.rain,
                        localizations.rainDesc),
                    _symbolCard(
                        context,
                        'thunderstorms',
                        localizations.thunderstorm,
                        localizations.thunderstormDesc),
                    _symbolCard(
                        context,
                        'thunderstorms-rain',
                        localizations.thunderstormWithRain,
                        localizations.thunderstormWithRainDesc),
                    _symbolCard(context, 'snow', localizations.snow,
                        localizations.snowDesc),
                    _symbolCard(context, 'fog', localizations.fog,
                        localizations.fogDesc),
                    _symbolCard(context, 'wind', localizations.wind,
                        localizations.windDesc),
                    _symbolCard(context, 'tornado', localizations.tornado,
                        localizations.tornadoDesc),
                    // Example of line style symbols
                    _symbolCard(
                        context,
                        'thunderstorms',
                        localizations.thunderstormLine,
                        localizations.lineStyleDesc,
                        useFilled: false),
                    _symbolCard(context, 'wind', localizations.windLine,
                        localizations.lineStyleDesc,
                        useFilled: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _symbolCard(
      BuildContext context, String symbolName, String title, String description,
      {bool useFilled = true}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WeatherSymbolWidget(
              symbolName: symbolName,
              useFilled: useFilled,
              size: 60.0,
            ),
            // const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                description,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
