import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../services/map_service.dart';
import '../theme/app_theme.dart';

/// A unified map widget that renders either OpenStreetMap (flutter_map)
/// or Google Maps based on [MapService.instance.provider].
///
/// Defaults to OSM (free, no API key). Call [MapService.instance.setUseGoogleMaps()]
/// at startup to switch to Google Maps as a fallback.
class RozgarMap extends StatefulWidget {
  /// Initial camera center latitude.
  final double initialLat;

  /// Initial camera center longitude.
  final double initialLng;

  /// Initial zoom level (default 14).
  final double initialZoom;

  /// Markers to display on the map.
  final List<MapMarker> markers;

  /// Called while the user is panning the map. Receives the new center.
  final void Function(double lat, double lng)? onCameraMove;

  /// Called when the camera stops moving (user lifted finger).
  final VoidCallback? onCameraIdle;

  /// If true, show the centred pin drop overlay (ride-app style picker).
  /// Use with [onCameraMove] / [onCameraIdle] to track the pin location.
  final bool showCenteredPin;

  /// If true, enable zoom + my-location controls on Google Maps.
  final bool showZoomControls;

  /// Provide an external controller for programmatic camera manipulation.
  final RozgarMapController? controller;

  /// Container height. Null = shrink-wrap to content.
  final double? height;

  /// Tile provider for OSM. Defaults to [CancellableNetworkTileProvider]
  /// for tile caching & cancellation. Override for testing.
  final osm.TileProvider? tileProvider;

  const RozgarMap({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialZoom = 14,
    this.markers = const [],
    this.onCameraMove,
    this.onCameraIdle,
    this.showCenteredPin = false,
    this.showZoomControls = false,
    this.controller,
    this.height,
    this.tileProvider,
  });

  @override
  State<RozgarMap> createState() => _RozgarMapState();
}

class _RozgarMapState extends State<RozgarMap> {
  final osm.MapController _osmController = osm.MapController();
  gmaps.GoogleMapController? _gmapController;
  latlong2.LatLng _lastCenter = const latlong2.LatLng(31.5204, 74.3587);

  bool get _useGoogleMaps => MapService.instance.useGoogleMaps;

  @override
  void initState() {
    super.initState();
    _lastCenter = latlong2.LatLng(widget.initialLat, widget.initialLng);
    if (widget.controller != null) {
      widget.controller!._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    try {
      _gmapController?.dispose();
    } catch (e) {
      debugPrint('Google Maps dispose error: $e');
    }
    super.dispose();
  }

  void _onGmapCreated(gmaps.GoogleMapController controller) {
    _gmapController = controller;
  }

  void _onGmapCameraMove(gmaps.CameraPosition pos) {
    _lastCenter = latlong2.LatLng(pos.target.latitude, pos.target.longitude);
    widget.onCameraMove?.call(pos.target.latitude, pos.target.longitude);
  }

  void _onOsmMapEvent(osm.MapEvent event) {
    if (event is osm.MapEventMoveEnd) {
      final center = event.camera.center;
      _lastCenter = center;
      widget.onCameraIdle?.call();
    } else if (event is osm.MapEventMove) {
      final center = event.camera.center;
      _lastCenter = center;
      widget.onCameraMove?.call(center.latitude, center.longitude);
    }
  }

  /// Move (or animate) the camera to [lat]/[lng] at [zoom].
  Future<void> animateTo(double lat, double lng, double zoom) async {
    if (_useGoogleMaps) {
      await _gmapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), zoom),
      );
      if (!mounted) return;
      _lastCenter = latlong2.LatLng(lat, lng);
      widget.onCameraMove?.call(lat, lng);
      widget.onCameraIdle?.call();
    } else {
      _osmController.move(latlong2.LatLng(lat, lng), zoom);
      _lastCenter = latlong2.LatLng(lat, lng);
      widget.onCameraMove?.call(lat, lng);
      widget.onCameraIdle?.call();
    }
  }

  ({double lat, double lng}) get currentCenter =>
      (lat: _lastCenter.latitude, lng: _lastCenter.longitude);

  Widget _buildOsmMap() {
    return osm.FlutterMap(
      options: osm.MapOptions(
        initialCenter: latlong2.LatLng(widget.initialLat, widget.initialLng),
        initialZoom: widget.initialZoom,
        onMapEvent: _onOsmMapEvent,
        // Use default interaction options (no rotation constraint needed)
      ),
      mapController: _osmController,
      children: [
        osm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.rozgar.rozgar',
          tileProvider: widget.tileProvider ?? CancellableNetworkTileProvider(),
        ),
        osm.MarkerLayer(
          markers: widget.markers.map((m) {
            return osm.Marker(
              point: latlong2.LatLng(m.lat, m.lng),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: m.onTap,
                child: _buildMarkerIcon(m),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarkerIcon(MapMarker marker) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: marker.isEmployer ? AppColors.teal600 : AppColors.amber500,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        marker.isEmployer ? Icons.work : Icons.construction,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Set<gmaps.Marker> _buildGmapMarkers() {
    return widget.markers.map((m) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(m.id),
        position: gmaps.LatLng(m.lat, m.lng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          m.isEmployer
              ? gmaps.BitmapDescriptor.hueGreen
              : gmaps.BitmapDescriptor.hueOrange,
        ),
        onTap: m.onTap,
        infoWindow: gmaps.InfoWindow(title: m.title, snippet: m.snippet),
      );
    }).toSet();
  }

  Widget _buildGmap() {
    return ClipRect(
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(widget.initialLat, widget.initialLng),
          zoom: widget.initialZoom,
        ),
        onMapCreated: _onGmapCreated,
        onCameraMove: _onGmapCameraMove,
        onCameraIdle: widget.onCameraIdle,
        markers: _buildGmapMarkers(),
        myLocationEnabled: false,
        myLocationButtonEnabled: widget.showZoomControls,
        zoomControlsEnabled: widget.showZoomControls,
        mapToolbarEnabled: false,
        mapType: gmaps.MapType.normal,
        style: _gmapDarkStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = _useGoogleMaps ? _buildGmap() : _buildOsmMap();

    Widget result;
    if (!widget.showCenteredPin) {
      result = mapWidget;
    } else {
      result = Stack(
        children: [
          mapWidget,
          // Fixed centered pin (ride-app style)
          const Center(
            child: _CenteredPinIcon(),
          ),
        ],
      );
    }

    // Apply fixed height only when specified; otherwise fill available space.
    if (widget.height != null) {
      result = SizedBox(height: widget.height, child: result);
    }

    return result;
  }

  /// Dark style for Google Maps.
  static const String _gmapDarkStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]}
  ]''';
}

/// Google Maps-style teardrop pin icon centred above the map.
class _CenteredPinIcon extends StatelessWidget {
  const _CenteredPinIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow pin
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.location_on, size: 48, color: Colors.black26),
          ),
          // Main pin
          const Icon(Icons.location_on, size: 48, color: AppColors.teal600),
          // White centre dot
          Positioned(
            left: 0,
            right: 0,
            top: 8,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// External controller for programmatic camera manipulation.
class RozgarMapController {
  _RozgarMapState? _state;

  void _attach(_RozgarMapState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void dispose() {
    _detach();
  }

  /// Move camera to [lat]/[lng] at [zoom].
  Future<void> animateTo(double lat, double lng, double zoom) async {
    final s = _state;
    if (s == null || !s.mounted) return;
    await s.animateTo(lat, lng, zoom);
  }

  /// Get current map center (works for both OSM and Google Maps).
  ({double lat, double lng})? get currentCenter => _state?.currentCenter;
}
