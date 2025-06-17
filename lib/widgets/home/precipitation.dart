import 'package:flutter/material.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class Precipitation extends StatelessWidget {
  const Precipitation({
    super.key,
    required this.p,
    this.compact = false,
  });

  final ForecastPoint p;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(-4, compact ? 6 : 1),
              child: WeatherSymbolWidget(symbolName: 'raindrop', size: compact ? 25 : 30),
            ),
            Transform.translate(
              offset: Offset(-7, compact ? 4 : 0),
              child: Text(
                '${p.probabilityOfPrecipitation.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Text(
          '${p.precipitation.toStringAsFixed(1)} mm',
        ),
      ],
    );
  }
}
