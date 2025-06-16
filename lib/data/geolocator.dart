import 'package:geolocator/geolocator.dart';

/// Enum representing possible geolocation errors
enum GeolocationStatus {
  /// Location services are disabled on the device
  locationServicesDisabled,

  /// Location permissions are denied
  permissionDenied,

  /// Location permissions are permanently denied
  permissionDeniedForever,

  /// Success - no error
  success
}

/// Class to hold the result of a geolocation attempt
class GeolocationResult {
  /// The position if successful
  final Position? position;

  /// The status of the geolocation attempt
  final GeolocationStatus status;

  /// Constructor
  GeolocationResult({this.position, required this.status});

  /// Check if the result is successful
  bool get isSuccess => status == GeolocationStatus.success;
}

/// Determine the current position of the device.
///
/// Returns a GeolocationResult object that contains both the position (if successful)
/// and a status indicating success or the type of error that occurred.
Future<GeolocationResult> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return GeolocationResult(
      status: GeolocationStatus.locationServicesDisabled
    );
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return GeolocationResult(
        status: GeolocationStatus.permissionDenied
      );
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return GeolocationResult(
      status: GeolocationStatus.permissionDeniedForever
    );
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  final position = await Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.low
    )
  );
  return GeolocationResult(
    position: position,
    status: GeolocationStatus.success
  );
}
