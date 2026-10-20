import 'dart:developer' as dev;

import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  /// Returns the device's current position, or null when location services are
  /// off or permission is not granted. Prompts for permission when [request] is true.
  static Future<Position?> current({bool request = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      dev.log('[LocationService] current error: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  static Future<bool> isDeniedForever() async =>
      await Geolocator.checkPermission() == LocationPermission.deniedForever;

  static Future<bool> openSettings() => Geolocator.openAppSettings();
}
