import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/providers.dart';
import '../../providers/app_state.dart' show WorkerEntry;
import '../../theme/app_theme.dart';
import '../../utils/geo.dart';
import '../../data/categories.dart';
import '../../models/job.dart';
import '../../services/map_service.dart';
import '../../widgets/rozgar_map.dart';

class NearbyWorkersMap extends ConsumerStatefulWidget {
  final ValueChanged<String> onOpenChat;
  final ValueChanged<String>? onOpenProfile;

  const NearbyWorkersMap({
    super.key,
    required this.onOpenChat,
    this.onOpenProfile,
  });

  @override
  ConsumerState<NearbyWorkersMap> createState() => _NearbyWorkersMapState();
}

class _NearbyWorkersMapState extends ConsumerState<NearbyWorkersMap> {
  String _selectedCategoryFilter = 'all';
  WorkerEntry? _selectedWorker;
  final RozgarMapController _mapController = RozgarMapController();
  bool _isLocating = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<WorkerEntry> _getFilteredWorkers() {
    final workers = ref.watch(workerProvider).allWorkers;
    return workers.where((w) {
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
        if (mounted) setState(() => _isLocating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLocating = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        _mapController.animateTo(pos.latitude, pos.longitude, 14);
        setState(() => _isLocating = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileNotifier = ref.watch(profileProvider);
    final empLocation = profileNotifier.employerProfile?.homeLocation;
    final filteredWorkers = _getFilteredWorkers();

    final markers = filteredWorkers.map((w) {
      final loc = w.details.currentLocation;
      return MapMarker(
        id: w.profile.id,
        lat: loc.lat,
        lng: loc.lng,
        title: w.profile.displayName,
        snippet: '${w.details.averageRating} ★ · ${w.details.totalJobsCompleted} jobs',
        onTap: () => setState(() => _selectedWorker = w),
      );
    }).toList();

    return Stack(
      children: [
        // Map
        Positioned.fill(
          child: RozgarMap(
            initialLat: empLocation?.lat ?? 31.5204,
            initialLng: empLocation?.lng ?? 74.3587,
            initialZoom: 13,
            markers: markers,
            controller: _mapController,
            showZoomControls: true,
          ),
        ),

        // Category filter chips
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _selectedCategoryFilter == 'all',
                  onTap: () => setState(() => _selectedCategoryFilter = 'all'),
                ),
                const SizedBox(width: 6),
                ...seededCategories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChip(
                    label: cat.nameEn,
                    isActive: _selectedCategoryFilter == cat.id,
                    onTap: () => setState(() => _selectedCategoryFilter = cat.id),
                  ),
                )),
              ],
            ),
          ),
        ),

        // GPS recenter button
        Positioned(
          right: 12,
          bottom: _selectedWorker != null ? 200 : 24,
          child: GestureDetector(
            onTap: _isLocating ? null : _recenterGps,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: _isLocating
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.my_location, size: 20, color: AppColors.teal600),
            ),
          ),
        ),

        // Worker count badge
        Positioned(
          left: 12,
          bottom: _selectedWorker != null ? 200 : 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 14, color: AppColors.teal600),
                const SizedBox(width: 6),
                Text(
                  '${filteredWorkers.length} workers nearby',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700),
                ),
              ],
            ),
          ),
        ),

        // Selected worker bottom sheet
        if (_selectedWorker != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _WorkerBottomSheet(
              worker: _selectedWorker!,
              onClose: () => setState(() => _selectedWorker = null),
              onChat: () => widget.onOpenChat(_selectedWorker!.profile.id),
              onProfile: widget.onOpenProfile != null
                  ? () => widget.onOpenProfile!(_selectedWorker!.profile.id)
                  : null,
              onInvite: () {
                final jobs = ref.read(jobProvider).jobs;
                final openJob = jobs.where((j) => j.status == JobStatus.open).firstOrNull;
                if (openJob != null) {
                  final employerId = ref.read(profileProvider).employerProfile?.id ?? '';
                  ref.read(coordinatorProvider.notifier).hireWorker(
                    jobId: openJob.id,
                    workerProfileId: _selectedWorker!.profile.id,
                    employerProfileId: employerId,
                  );
                }
                setState(() => _selectedWorker = null);
              },
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.teal600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.teal600 : AppColors.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _WorkerBottomSheet extends StatelessWidget {
  final WorkerEntry worker;
  final VoidCallback onClose;
  final VoidCallback onChat;
  final VoidCallback? onProfile;
  final VoidCallback onInvite;

  const _WorkerBottomSheet({
    required this.worker,
    required this.onClose,
    required this.onChat,
    this.onProfile,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Worker info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal200),
                ),
                child: Center(
                  child: Text(
                    worker.profile.displayName.isNotEmpty
                        ? worker.profile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          worker.profile.displayName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
                        ),
                        if (worker.profile.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: AppColors.teal600),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: AppColors.amber500),
                        const SizedBox(width: 3),
                        Text(
                          '${worker.details.averageRating}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${worker.details.totalJobsCompleted} jobs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDistance(calculateDistanceKm(
                            lat1: worker.details.currentLocation.lat,
                            lng1: worker.details.currentLocation.lng,
                            lat2: 31.5204,
                            lng2: 74.3587,
                          )),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 20, color: AppColors.slate400),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.teal600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Chat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            if (onProfile != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onProfile,
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
