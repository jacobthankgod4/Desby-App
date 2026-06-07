import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

/// Location service for getting user's GPS position
/// Uses geolocator package for cross-platform location
class LocationService {
  /// Check if location services are enabled and permissions granted
  static Future<bool> isLocationPermissionGranted() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] Location services disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationService] Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get current user position
  /// Returns null if unavailable, falls back to Lagos center
  static Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await isLocationPermissionGranted();
      if (!hasPermission) {
        return null;
      }

final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = LatLng(position.latitude, position.longitude);
      debugPrint('[LocationService] Got location: $location');
      return location;
    } catch (e) {
      debugPrint('[LocationService] Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate distance in minutes (walking estimate)
  /// Assumes average walking speed of 5 km/h = 83m/min
  static int calculateDistanceMinutes(LatLng from, LatLng to) {
    final meters = calculateDistance(from, to);
    return (meters / 83).round().clamp(1, 60);
  }

  /// Default Lagos location fallback
  static const LatLng defaultLocation = LatLng(6.5244, 3.3792);
  
  /// Ikeja location fallback if Lagos location unavailable
  static const LatLng ikejaLocation = LatLng(6.5969, 3.3215);
}
