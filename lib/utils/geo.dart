import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Calculates straight-line distance in kilometers between two geo coordinates.
/// Mirrors PostGIS ST_DWithin / ST_DistanceSphere behavior.
double calculateDistanceKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const double R = 6371; // Earth radius in kilometers
  final double dLat = _toRad(lat2 - lat1);
  final double dLng = _toRad(lng2 - lng1);
  final double rLat1 = _toRad(lat1);
  final double rLat2 = _toRad(lat2);

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLng / 2) *
          math.sin(dLng / 2) *
          math.cos(rLat1) *
          math.cos(rLat2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final double distance = R * c;

  return double.parse((distance).toStringAsFixed(1));
}

double _toRad(double degrees) => degrees * math.pi / 180;

/// Formats distance into a human readable string (e.g. "1.2 km away")
String formatDistance(double distanceKm) {
  if (distanceKm < 0.2) return 'Very close (< 200m)';
  return '$distanceKm km away';
}

/// Reverse geocode via Nominatim (free OSM API, no key required).
/// Returns a human-readable address string for the given coordinates.
/// Falls back to a simple mock if the request fails.
Future<String> reverseGeocode(double lat, double lng) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&countrycodes=pk',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    }
  } catch (e) {
    debugPrint('reverseGeocode error: $e');
  }
  return reverseGeocodeMock(lat, lng);
}

/// Search locations via Nominatim (free OSM API, no key required).
/// Returns a list of {name, lat, lng} maps matching the query.
Future<List<Map<String, dynamic>>> searchLocations(String query) async {
  if (query.trim().isEmpty) return [];
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(query)}&limit=5&countrycodes=pk',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((place) {
        final p = place as Map<String, dynamic>;
        return {
          'name': p['display_name'] as String? ?? query,
          'lat': double.tryParse(p['lat'] as String? ?? '') ?? 0.0,
          'lng': double.tryParse(p['lon'] as String? ?? '') ?? 0.0,
        };
      }).toList();
    }
  } catch (e) {
    debugPrint('searchLocations error: $e');
  }
  return [];
}

/// Reverses coordinates into a readable address mock helper (synchronous fallback).
String reverseGeocodeMock(double lat, double lng) {
  if (lat > 33.0) return 'Islamabad / Rawalpindi, Pakistan';
  if (lat > 32.0) return 'Gujranwala / Sialkot, Pakistan';
  if (lat > 31.51 && lat <= 31.55) return 'Gulberg / Cantt Area, Lahore';
  if (lat > 31.48 && lat <= 31.51) return 'Model Town / Garden Town, Lahore';
  if (lat > 31.45 && lat <= 31.48) return 'Johar Town / Faisal Town, Lahore';
  if (lat > 31.3 && lat <= 31.45 && lng > 74.38) return 'DHA Phase 5 / Phase 6, Lahore';
  if (lat > 31.3 && lat <= 31.45) return 'Ferozepur Road / Iqbal Town, Lahore';
  if (lat > 30.0) return 'Faisalabad / Sahiwal, Pakistan';
  if (lat > 25.0) return 'Karachi / Hyderabad, Pakistan';
  if (lat > 24.0) return 'Karachi / Hyderabad, Pakistan';
  return 'Punjab, Pakistan';
}
