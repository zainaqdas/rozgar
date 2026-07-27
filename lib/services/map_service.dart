import 'package:flutter/material.dart';

/// Which map provider the app should use.
enum MapProviderType {
  /// OpenStreetMap via flutter_map (free, no API key needed)
  osm,

  /// Google Maps via google_maps_flutter (requires API key)
  googleMaps,
}

/// A marker displayed on either map provider.
class MapMarker {
  final String id;
  final double lat;
  final double lng;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(id, lat, lng);
  final String? snippet;
  final VoidCallback? onTap;
  final bool isEmployer;

  const MapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    this.title = '',
    this.snippet,
    this.onTap,
    this.isEmployer = false,
  });
}

/// Central service for selecting and configuring the map provider.
///
/// Defaults to OpenStreetMap (free, no API key required).
/// Call [setUseGoogleMaps] at startup if a valid Google Maps API key
/// is configured, otherwise OSM is used automatically.
class MapService {
  MapService._();
  static final MapService _instance = MapService._();
  static MapService get instance => _instance;

  MapProviderType _provider = MapProviderType.osm;

  /// The currently active map provider type.
  MapProviderType get provider => _provider;

  /// Whether Google Maps is currently in use.
  bool get useGoogleMaps => _provider == MapProviderType.googleMaps;

  /// Switch to Google Maps (fallback). Call this at app start if a
  /// valid Google Maps API key is available.
  void setUseGoogleMaps() {
    _provider = MapProviderType.googleMaps;
  }

  /// Switch back to OpenStreetMap.
  void setUseOsm() {
    _provider = MapProviderType.osm;
  }
}
