import 'package:xml/xml.dart' as xml;

/// Model class for Harmonie XML API response
///
/// This class represents the response from the FMI Harmonie API, with a focus on
/// the time series data for various weather parameters.
class HarmonieResponse {
  /// Map of time series data, keyed by parameter name
  ///
  /// The keys are parameter names (e.g., 'Temperature', 'Humidity'), and the values
  /// are [HarmonieTimeSeries] objects containing the time series data for that parameter.
  final Map<String, HarmonieTimeSeries> timeSeries;

  /// Creates a new HarmonieResponse instance
  const HarmonieResponse({
    required this.timeSeries,
  });

  /// Creates a HarmonieResponse from an XML document
  ///
  /// This factory method takes an XML document from the FMI Harmonie API
  /// and converts it to a [HarmonieResponse] instance.
  factory HarmonieResponse.fromXml(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final members = document.findAllElements('wfs:member').toList();

    if (members.isEmpty) {
      throw Exception('No forecast data available from FMI Harmonie model');
    }

    // Parameter names in the order they appear in the response
    final parameterNames = [
      'Humidity',
      'Temperature',
      'WindDirection',
      'WindSpeedMS',
      'WindGust',
      'Precipitation1h',
      'WeatherSymbol3',
      'feelslike',
    ];

    final Map<String, HarmonieTimeSeries> timeSeries = {};

    // Parse the time series data for each parameter
    for (int i = 0; i < members.length && i < parameterNames.length; i++) {
      final parameterName = parameterNames[i];
      final member = members[i];
      timeSeries[parameterName] = HarmonieTimeSeries.fromXml(member);
    }

    return HarmonieResponse(timeSeries: timeSeries);
  }

  /// Gets all unique time points across all time series
  ///
  /// Returns a sorted list of all unique time points from all time series.
  List<DateTime> getAllTimePoints() {
    final allTimePoints = <DateTime>{};

    for (final series in timeSeries.values) {
      for (final point in series.timeValues) {
        allTimePoints.add(point.time);
      }
    }

    final sortedTimePoints = allTimePoints.toList()..sort();
    return sortedTimePoints;
  }

  /// Finds a value for a specific parameter and time
  ///
  /// Returns the value for the specified parameter at the specified time,
  /// or null if no value is found.
  double? findValueForTime(String parameterName, DateTime time) {
    final series = timeSeries[parameterName];
    if (series == null) return null;

    for (final point in series.timeValues) {
      if (point.time.isAtSameMomentAs(time)) {
        return point.value;
      }
    }

    return null;
  }
}

/// Model class for a time series of a specific weather parameter
///
/// This class represents the time series data for a specific weather parameter,
/// such as temperature, humidity, etc.
class HarmonieTimeSeries {
  /// List of time-value pairs in this time series
  final List<HarmonieTimeValue> timeValues;

  /// Creates a new HarmonieTimeSeries instance
  const HarmonieTimeSeries({
    required this.timeValues,
  });

  /// Creates a HarmonieTimeSeries from an XML element
  ///
  /// This factory method takes an XML element from the FMI Harmonie API
  /// and converts it to a [HarmonieTimeSeries] instance.
  factory HarmonieTimeSeries.fromXml(xml.XmlElement member) {
    final timeValues = <HarmonieTimeValue>[];

    try {
      final points = member
          .findAllElements('omso:PointTimeSeriesObservation')
          .first
          .findAllElements('om:result')
          .first
          .findAllElements('wml2:MeasurementTimeseries')
          .first
          .findAllElements('wml2:point');

      for (final point in points) {
        try {
          final timeElement = point
              .findAllElements('wml2:MeasurementTVP')
              .first
              .findAllElements('wml2:time')
              .first;

          final valueElement = point
              .findAllElements('wml2:MeasurementTVP')
              .first
              .findAllElements('wml2:value')
              .first;

          final time = DateTime.parse(timeElement.innerText);
          final value = double.tryParse(valueElement.innerText);

          if (value != null && !value.isNaN) {
            timeValues.add(HarmonieTimeValue(time: time, value: value));
          }
        } catch (e) {
          // Skip this point if there's an error
          print('Error parsing time series point: $e');
        }
      }
    } catch (e) {
      print('Error parsing time series: $e');
    }

    return HarmonieTimeSeries(timeValues: timeValues);
  }
}

/// Model class for a single time-value pair in a time series
///
/// This class represents a single time-value pair in a time series,
/// with a timestamp and a value.
class HarmonieTimeValue {
  /// The timestamp for this time-value pair
  final DateTime time;

  /// The value at this timestamp
  final double value;

  /// Creates a new HarmonieTimeValue instance
  const HarmonieTimeValue({
    required this.time,
    required this.value,
  });
}
