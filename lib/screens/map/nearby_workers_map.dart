import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/geo.dart';
import '../../data/categories.dart';
import '../../models/location_point.dart';
import '../../models/job.dart';
import '../../services/map_service.dart';
import '../../widgets/rozgar_map.dart';

class NearbyWorkersMap extends StatefulWidget {
  final AppState appState;
  final ValueChanged<String> onOpenChat;
  final ValueChanged<String>? onOpenProfile;

  const NearbyWorkersMap({
    super.key,
    required this.appState,
    required this.onOpenChat,
    this.onOpenProfile,
  });

  @override
  State<NearbyWorkersMap> createState() => _NearbyWorkersMapState();
}

class _NearbyWorkersMapState extends State<NearbyWorkersMap> {
  String _selectedCategoryFilter = 'all';
  WorkerEntry? _selectedWorker;
  final RozgarMapController _mapController = RozgarMapController();
  bool _isLocating = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<WorkerEntry> _getFilteredWorkers(AppState state) {
    return state.allWorkers.where((w) {
      if (!w.details.isOnlineForMap) return false;
      if (_selectedCategoryFilter == 'all') return true;
      return w.details.categoryIds.any(
        (cat) => cat.contains(_selectedCategoryFilter) || _selectedCategoryFilter.contains(cat),
      );
    }).toList();
  }

  Future<void> _recenterGps() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (!mounted) return;
        setState(() => _isLocating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
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
    } catch (e) {
      debugPrint('GPS error: $e');
    }
    if (!mounted) return;
    setState(() => _isLocating = false);
  }

  List<MapMarker> _buildMarkers(AppState state) {
    final empLocation = state.employerProfile?.homeLocation;
    final empLat = empLocation?.lat ?? 31.5204;
    final empLng = empLocation?.lng ?? 74.3587;
    final filteredWorkers = _getFilteredWorkers(state);
    final markers = <MapMarker>[];

    // Employer marker
    markers.add(MapMarker(
      id: 'employer-location',
      lat: empLat,
      lng: empLng,
      title: 'Your Location',
      snippet: 'Gulberg III, Lahore',
      isEmployer: true,
    ));

    // Worker markers
    for (final worker in filteredWorkers) {
      markers.add(MapMarker(
        id: 'worker-${worker.profile.id}',
        lat: worker.details.currentLocation.lat,
        lng: worker.details.currentLocation.lng,
        title: worker.profile.displayName,
        snippet: '${worker.details.averageRating}',
        onTap: () => setState(() => _selectedWorker = worker),
        isEmployer: false,
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final empLocation = state.employerProfile?.homeLocation;
    final empLat = empLocation?.lat ?? 31.5204;
    final empLng = empLocation?.lng ?? 74.3587;
    final filteredWorkers = _getFilteredWorkers(state);
    final markers = _buildMarkers(state);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.slate950,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Active (${filteredWorkers.length})',
                  isActive: _selectedCategoryFilter == 'all',
                  onTap: () => setState(() => _selectedCategoryFilter = 'all'),
                ),
                const SizedBox(width: 6),
                ...seededCategories.map((cat) => _FilterChip(
                      label: cat.nameEn,
                      isActive: _selectedCategoryFilter == cat.id,
                      onTap: () => setState(() => _selectedCategoryFilter = cat.id),
                    )),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              RozgarMap(
                initialLat: empLat,
                initialLng: empLng,
                initialZoom: 14,
                markers: markers,
                showZoomControls: false,
                controller: _mapController,
              ),
              // Online count overlay
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${filteredWorkers.length} workers nearby',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              // GPS Recenter button
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal600),
                            )
                          : const Icon(Icons.my_location, size: 20, color: AppColors.teal600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedWorker != null)
          _WorkerCard(
            worker: _selectedWorker!,
            appState: state,
            onClose: () => setState(() => _selectedWorker = null),
            onChat: () {
              widget.onOpenChat(_selectedWorker!.profile.id);
              setState(() => _selectedWorker = null);
            },
            onViewProfile: widget.onOpenProfile != null
                ? () {
                    widget.onOpenProfile!(_selectedWorker!.profile.id);
                    setState(() => _selectedWorker = null);
                  }
                : null,
            onInvite: () {
              final openJob = state.jobs.where((j) => j.status == JobStatus.open).firstOrNull;
              if (openJob != null) {
                state.hireWorker(openJob.id, _selectedWorker!.profile.id);
              }
              widget.onOpenChat(_selectedWorker!.profile.id);
              setState(() => _selectedWorker = null);
            },
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emerald400 : AppColors.slate900.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: AppColors.slate700.withValues(alpha: 0.8)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppColors.teal950 : AppColors.slate300)),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerEntry worker;
  final AppState appState;
  final VoidCallback onClose;
  final VoidCallback onChat;
  final VoidCallback? onViewProfile;
  final VoidCallback onInvite;

  const _WorkerCard({
    required this.worker,
    required this.appState,
    required this.onClose,
    required this.onChat,
    this.onViewProfile,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final empLocation = appState.employerProfile?.homeLocation ??
        const LocationPoint(lat: 31.5204, lng: 74.3587, address: '');
    final distanceKm = calculateDistanceKm(
      lat1: empLocation.lat,
      lng1: empLocation.lng,
      lat2: worker.details.currentLocation.lat,
      lng2: worker.details.currentLocation.lng,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.slate700.withValues(alpha: 0.8))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  worker.profile.profilePhotoUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(worker.profile.displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate100)),
                    if (worker.profile.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle, size: 14, color: AppColors.emerald400),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star, size: 12, color: AppColors.amber400),
                    const SizedBox(width: 2),
                    Text('${worker.details.averageRating}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber400)),
                    const SizedBox(width: 6),
                    Text('${worker.details.totalJobsCompleted} jobs',
                        style: const TextStyle(fontSize: 10, color: AppColors.slate400)),
                    const SizedBox(width: 6),
                    Text(formatDistance(distanceKm),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.emerald400)),
                  ]),
                ]),
              ),
              GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 18, color: AppColors.slate400)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate950.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate800),
            ),
            child: Text('"${worker.details.bio}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slate300)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('Rate: ${worker.details.rateNote}',
                style: const TextStyle(fontSize: 10, color: AppColors.slate400)),
            const Spacer(),
            Text('Response: ${worker.details.responseTimeAvgMinutes} mins',
                style: const TextStyle(fontSize: 10, color: AppColors.emerald400)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.emerald400.withValues(alpha: 0.4)),
                    color: AppColors.slate800,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_outlined, size: 14, color: AppColors.emerald400),
                    SizedBox(width: 4),
                    Text('Chat',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.emerald400)),
                  ]),
                ),
              ),
            ),
            if (onViewProfile != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onViewProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate600.withValues(alpha: 0.4)),
                      color: AppColors.slate800,
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.slate300),
                      SizedBox(width: 4),
                      Text('Profile',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate300)),
                    ]),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: onInvite,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.emerald400, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.work, size: 14, color: AppColors.teal950),
                    SizedBox(width: 4),
                    Text('Invite', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal950)),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
