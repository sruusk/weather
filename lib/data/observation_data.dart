import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import 'location.dart';
import 'observation_station.dart';
import 'observation_station_location.dart';
import 'time_series.dart';

/// A class for fetching and caching weather observation data
class ObservationData {
  // Singleton instance
  static final ObservationData _instance = ObservationData._internal();

  // Factory constructor to return the singleton instance
  factory ObservationData() {
    return _instance;
  }

  // Private constructor for singleton pattern
  ObservationData._internal();

  // Cache for all observation stations (not coordinate-dependent)
  List<ObservationStationLocation>? _allStationsCache;

  // Cache for station observations
  final Map<String, ObservationStation> _observationsCache = {};

  // Cache for closest stations to a location (not coordinate-dependent)
  final Map<String, List<ObservationStation>> _stationObservationsCache = {};

  /// Clears all cached data
  void clearCache() {
    if(kDebugMode) print('Clearing all cached data');
    _allStationsCache = null;
    _observationsCache.clear();
    _stationObservationsCache.clear();
  }

  /// Clears cached data for a specific location
  void clearCacheForLocation(Location location) {
    if(kDebugMode) print('Clearing cached data for location ${location.lat},${location.lon}');
    // We don't need to clear location-specific caches anymore since we're not using coordinates as keys
  }
  static const String baseUrl = 'https://opendata.fmi.fi/wfs?request=getFeature';

  static const List<String> observationStationParameters = [
    "humidity",
    "temperature",
    "dewpoint",
    "windspeedms",
    "winddirection",
    "windgust",
    "pri_pt1h_max", // precipitation intensity
    "snowdepth", // snow depth
    "p_sea", // pressure at sea level
    "ch1_aws", // cloud height
    "vis", // visibility
    "wawa", // weather
  ];

  /// Gets the 5 closest observation stations to the given location
  ///
  /// Returns a Future that completes with a list of ObservationStation objects
  /// Uses cached data if available
  Future<List<ObservationStation>> getClosestStations(Location location) async {
    // Get all stations (using cached data if available)
    final stations = await _getObservationStations(location.lat, location.lon);

    // Sort stations by distance
    stations.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

    // Get more than 5 stations in case some fail
    final closestStations = stations.take(10).toList();

    // Get observations for each station
    final List<ObservationStation> result = [];
    for (final station in closestStations) {
      try {
        final observations = await _getObservationsForStation(station);

        // Only add stations with valid temperature data
        if (observations.temperature != null &&
            observations.temperature!.isNotEmpty) {
          result.add(observations);

          // Once we have 5 valid stations, we can stop
          if (result.length >= 5) break;
        }
      } catch (e) {
        if(kDebugMode) print('Error getting observations for station ${station.name}: $e');
        // Continue to the next station
      }
    }

    return result;
  }

  /// Gets all observation stations and calculates their distance from the given coordinates
  /// Uses cached data if available
  Future<List<ObservationStationLocation>> _getObservationStations(double lat, double lon) async {
    // Check if we have cached all stations
    if (_allStationsCache != null) {
      if(kDebugMode) print('Using cached stations data');

      // Calculate distances for all stations
      final stations = _allStationsCache!.map((station) {
        // Create a copy of the station with updated distance
        final distance = _distanceBetweenCoordinates(lat, lon, station.lat, station.lon) / 1000; // Convert to km
        return ObservationStationLocation(
          identifier: station.identifier,
          name: station.name,
          region: station.region,
          country: station.country,
          countryCode: station.countryCode,
          lat: station.lat,
          lon: station.lon,
          distance: distance,
        );
      }).toList();

      return stations;
    }

    if(kDebugMode) print('Fetching new stations data');
    final url = '$baseUrl&storedquery_id=fmi::ef::stations';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load observation stations');
    }

    final document = xml.XmlDocument.parse(response.body);
    final members = document.findAllElements('wfs:member');

    final List<ObservationStationLocation> stations = [];

    for (final member in members) {
      try {
        final facility = member.findElements('ef:EnvironmentalMonitoringFacility').first;

        // Check if this is a weather station
        final belongsToElements = facility.findElements('ef:belongsTo');
        bool isWeatherStation = false;

        for (final belongsTo in belongsToElements) {
          final title = belongsTo.getAttribute('xlink:title') ?? '';
          if (title.toLowerCase().contains('sääasema')) {
            isWeatherStation = true;
            break;
          }
        }

        if (!isWeatherStation) continue;

        // Get station identifier
        final identifier = facility.findElements('gml:identifier').first.innerText;

        // Get station name, region, and country
        final nameElements = facility.findElements('gml:name');
        String? name, region, country;
        String countryCode = 'FI'; // Default to Finland

        for (final nameElement in nameElements) {
          final codeSpace = nameElement.getAttribute('codeSpace') ?? '';
          final text = nameElement.innerText;

          if (codeSpace.endsWith('name')) {
            name = text;
          } else if (codeSpace.endsWith('region')) {
            region = text;
          } else if (codeSpace.endsWith('country')) {
            country = text;
          }
        }

        if (name == null) continue;

        // Get station coordinates
        final point = facility.findAllElements('gml:Point').first;
        final pos = point.findElements('gml:pos').first.innerText.trim().split(' ');
        final stationLat = double.parse(pos[0]);
        final stationLon = double.parse(pos[1]);

        // Calculate distance
        final distance = _distanceBetweenCoordinates(lat, lon, stationLat, stationLon) / 1000; // Convert to km

        stations.add(ObservationStationLocation(
          identifier: identifier,
          name: name,
          region: region,
          country: country,
          countryCode: countryCode,
          lat: stationLat,
          lon: stationLon,
          distance: distance,
        ));
      } catch (e) {
        if(kDebugMode) print('Error parsing station: $e');
      }
    }

    // Cache all stations without distances
    _allStationsCache = stations.map((station) => ObservationStationLocation(
      identifier: station.identifier,
      name: station.name,
      region: station.region,
      country: station.country,
      countryCode: station.countryCode,
      lat: station.lat,
      lon: station.lon,
      // Don't include distance in the cached version
    )).toList();

    return stations;
  }

  /// Gets observations for a specific station
  Future<ObservationStation> _getObservationsForStation(ObservationStationLocation station) async {
    // Create a cache key based on the station identifier
    final cacheKey = station.identifier;

    // Check if we have cached data for this station
    if (_observationsCache.containsKey(cacheKey)) {
      if(kDebugMode) print('Using cached observations data for station ${station.name}');
      return _observationsCache[cacheKey]!;
    }

    if(kDebugMode) print('Fetching new observations data for station ${station.name}');
    final url = '$baseUrl&fmisid=${station.identifier}&storedquery_id=fmi::observations::weather::timevaluepair&parameters=${observationStationParameters.join(',')}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load observations for station ${station.name}');
    }

    final document = xml.XmlDocument.parse(response.body);
    final members = document.findAllElements('wfs:member');

    if (members.isEmpty) {
      throw Exception('No data for station ${station.name}');
    }

    // Parse time series data
    final List<List<TimeSeries>> timeSeriesData = [];
    for (final member in members) {
      final timeSeries = _parseTimeSeriesObservation(member);
      timeSeriesData.add(timeSeries);
    }

    // Get the time from the first observation
    final timeElements = members.first.findAllElements('gml:timePosition');
    if (timeElements.isEmpty) {
      throw Exception('No time data for station ${station.name}');
    }
    final time = DateTime.parse(timeElements.first.innerText);

    // Get filtered time series data for all parameters
    final List<TimeSeries>? humidity = timeSeriesData.isNotEmpty ?
        timeSeriesData[0].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? temperature = timeSeriesData.length > 1 ?
        timeSeriesData[1].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? dewPoint = timeSeriesData.length > 2 ?
        timeSeriesData[2].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? windSpeed = timeSeriesData.length > 3 ?
        timeSeriesData[3].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? windDirection = timeSeriesData.length > 4 ?
        timeSeriesData[4].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? windGust = timeSeriesData.length > 5 ?
        timeSeriesData[5].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? precipitation = timeSeriesData.length > 6 ?
        timeSeriesData[6].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? snowDepth = timeSeriesData.length > 7 ?
        timeSeriesData[7].where((item) => !item.value.isNaN).toList().map((item) {
          // Ensure snow depth is not negative
          return item.value < 0 ? TimeSeries(time: item.time, value: 0) : item;
        }).toList() : null;

    final List<TimeSeries>? pressure = timeSeriesData.length > 8 ?
        timeSeriesData[8].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? cloudBase = timeSeriesData.length > 9 ?
        timeSeriesData[9].where((item) => !item.value.isNaN).toList() : null;

    final List<TimeSeries>? visibility = timeSeriesData.length > 10 ?
        timeSeriesData[10].where((item) => !item.value.isNaN).toList() : null;

    //final List<TimeSeries>? weather = timeSeriesData.length > 11 ?
    //    timeSeriesData[11].where((item) => !item.value.isNaN).toList() : null;

    final result = ObservationStation(
      location: station,
      time: time,
      humidity: humidity,
      temperature: temperature,
      dewPoint: dewPoint,
      windSpeed: windSpeed,
      windDirection: windDirection,
      windGust: windGust,
      precipitation: precipitation,
      snowDepth: snowDepth,
      pressure: pressure,
      cloudBase: cloudBase,
      visibility: visibility,
    );

    // Cache the result
    _observationsCache[cacheKey] = result;

    return result;
  }

  /// Parses time series observation data from XML
  List<TimeSeries> _parseTimeSeriesObservation(xml.XmlNode node) {
    final points = node.findAllElements('wml2:point');
    final result = <TimeSeries>[];

    for (final point in points) {
      try {
        final timeElements = point.childElements.first.findElements('wml2:time');
        final valueElements = point.childElements.first.findElements('wml2:value');

        if (timeElements.isEmpty || valueElements.isEmpty) {
          continue; // Skip this point if either time or value is missing
        }

        final timeElement = timeElements.first;
        final valueElement = valueElements.first;

        final time = DateTime.parse(timeElement.innerText);
        final value = double.tryParse(valueElement.innerText) ?? double.nan;

        if(value.isNaN) {
          continue; // Skip this point if the value is not a number
        }

        result.add(TimeSeries(time: time, value: value));
      } catch (e) {
        if(kDebugMode) print('Error parsing time series point: $e');
        // Continue to the next point if there's an error
      }
    }

    return result;
  }

  /// Calculates the distance between two coordinates in meters
  double _distanceBetweenCoordinates(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth radius in meters
    final phi1 = lat1 * pi / 180; // φ, λ in radians
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) *
        sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // in meters
  }
}
