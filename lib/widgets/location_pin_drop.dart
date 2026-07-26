import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_point.dart';
import '../widgets/rozgar_map.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import '../utils/geo.dart';

/// Reusable ride-app style location pin-drop widget with Google Maps-style pin.
class LocationPinDrop extends StatefulWidget {
  final LocationPoint? initialLocation;
  final ValueChanged<LocationPoint> onConfirmLocation;
  final LanguageOption language;
  final String? title;
  final String? confirmBtnText;
  final VoidCallback? onClose;

  const LocationPinDrop({
    super.key,
    this.initialLocation,
    required this.onConfirmLocation,
    this.language = LanguageOption.en,
    this.title,
    this.confirmBtnText,
    this.onClose,
  });

  @override
  State<LocationPinDrop> createState() => _LocationPinDropState();
}

class _LocationPinDropState extends State<LocationPinDrop> {
  final RozgarMapController _mapController = RozgarMapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  double _lat = 30.3753;
  double _lng = 69.3451;
  String _addressText = '';
  bool _isLocating = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchTaskId;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _lat = widget.initialLocation!.lat;
      _lng = widget.initialLocation!.lng;
      _addressText = widget.initialLocation!.address;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCenterAndGeocode());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryGpsOnInit());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _syncCenterAndGeocode() {
    final center = _mapController.currentCenter;
    if (center != null) {
      _lat = center.lat;
      _lng = center.lng;
    }
    _reverseGeocodeCurrent();
  }

  Future<void> _tryGpsOnInit() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted == LocationPermission.denied) return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      await _mapController.animateTo(pos.latitude, pos.longitude, 15);
      await _reverseGeocodeCurrent();
    } catch (_) {}
  }

  Future<void> _reverseGeocodeCurrent() async {
    final center = _mapController.currentCenter;
    if (center != null) {
      _lat = center.lat;
      _lng = center.lng;
    }
    final addr = await reverseGeocode(_lat, _lng);
    if (mounted) {
      setState(() => _addressText = addr);
    }
  }

  Future<void> _recenterGps() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _isLocating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false);
          return;
        }
      }
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _mapController.animateTo(pos.latitude, pos.longitude, 16);
      final addr = await reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _addressText = addr;
        });
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
    setState(() => _isLocating = false);
  }

  void _onCameraMove(double lat, double lng) {
    _lat = lat;
    _lng = lng;
  }

  void _onCameraIdle() async {
    final center = _mapController.currentCenter;
    if (center != null) {
      _lat = center.lat;
      _lng = center.lng;
    }
    setState(() => _addressText = 'Updating…');
    await _reverseGeocodeCurrent();
  }

  void _onSearchChanged(String query) {
    _searchTaskId = query; // simple debounce key
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (_searchTaskId != query) return;
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _hasSearched = false;
        });
        return;
      }
      setState(() => _isSearching = true);
      final results = await searchLocations(query);
      if (_searchTaskId != query) return;
      if (mounted) {
        setState(() {
          _searchResults = results;
          _hasSearched = true;
        });
      }
    });
  }

  void _onSearchSubmit(String query) {
    if (query.trim().isEmpty) return;
    _searchFocusNode.unfocus();
    setState(() => _isSearching = true);
    _searchResults = [];
    _selectFirstResult(query);
  }

  Future<void> _selectFirstResult(String query) async {
    final results = await searchLocations(query);
    if (!mounted) return;
    if (results.isNotEmpty) {
      _selectSearchResult(results.first);
    } else {
      setState(() => _hasSearched = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> loc) {
    final lat = loc['lat'] as double;
    final lng = loc['lng'] as double;
    final name = loc['name'] as String;
    _searchController.text = '';
    _searchResults = [];
    _isSearching = false;
    _hasSearched = false;
    _searchFocusNode.unfocus();
    setState(() {
      _lat = lat;
      _lng = lng;
      _addressText = name;
    });
    _mapController.animateTo(lat, lng, 16);
  }

  void _confirmLocation() {
    final parts = _addressText.split(',');
    final city = parts.length >= 3 ? parts[parts.length - 3].trim() : '';
    widget.onConfirmLocation(LocationPoint(
      lat: _lat,
      lng: _lng,
      address: _addressText,
      city: city,
    ));
  }

  /// Shorten long Nominatim display_name for search results.
  String _shortenName(String name) {
    if (name.length <= 60) return name;
    final idx = name.indexOf(',');
    if (idx > 0 && idx < 60) return name.substring(0, idx);
    return '${name.substring(0, 57)}...';
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.slate200)),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmit,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: AppTranslations.t('searchAddressPlaceholder', lang),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.teal600),
                      suffixIcon: widget.onClose != null
                          ? GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(Icons.close, size: 18, color: AppColors.slate400),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final loc = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, size: 16, color: AppColors.teal600),
                            title: Text(
                              _shortenName(loc['name'] as String? ?? ''),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(loc),
                          );
                        },
                      ),
                    ),
                  ),
                if (!_isSearching && _hasSearched && _searchResults.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: const Text(
                      'No locations found',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                  ),
              ],
            ),
          ),

          // Map Area — fills remaining space
          Expanded(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                RozgarMap(
                  initialLat: _lat,
                  initialLng: _lng,
                  initialZoom: 15,
                  controller: _mapController,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  showCenteredPin: true,
                ),

                // Centered pin label (shown above pin for both providers)
                if (_addressText.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.teal200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                          ],
                        ),
                        child: Text(
                          _addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal900,
                          ),
                        ),
                      ),
                    ),
                  ),

                // GPS Recenter Button
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: _recenterGps,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                        ],
                      ),
                      child: Center(
                        child: _isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal600,
                                ),
                              )
                            : const Icon(Icons.my_location, size: 20, color: AppColors.teal600),
                      ),
                    ),
                  ),
                ),

                // Coordinates overlay
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '$_lat, $_lng',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.slate200)),
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: ElevatedButton.icon(
                onPressed: _confirmLocation,
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text(
                  widget.confirmBtnText ?? AppTranslations.t('confirmLocationBtn', lang),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
