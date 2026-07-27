import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../utils/geo.dart';
import '../../models/job.dart';
import '../../models/location_point.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class WorkerHome extends StatelessWidget {
  final AppState appState;
  final ValueChanged<Job> onOpenJobDetails;
  final VoidCallback onOpenMapClick;

  const WorkerHome({
    super.key,
    required this.appState,
    required this.onOpenJobDetails,
    required this.onOpenMapClick,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    final details = appState.workerDetails;
    final workerLoc = details?.currentLocation;
    if (workerLoc == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 48, color: AppColors.slate300),
              SizedBox(height: 16),
              Text(
                'Location not set',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate700),
              ),
              SizedBox(height: 8),
              Text(
                'Update your profile location to see nearby jobs.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
            ],
          ),
        ),
      );
    }
    final radiusKm = details?.notificationRadiusKm ?? 15;
    final categoryIds = details?.categoryIds ?? [];
    final nearbyJobs = appState.getJobsNearWorker(
      workerLocation: workerLoc,
      radiusKm: radiusKm,
      categoryIds: categoryIds,
    );

    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(milliseconds: 600), () => appState.refresh()),
      color: AppColors.teal600,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            index: 0,
            child: _PresenceBanner(
              isOnline: details?.isOnlineForMap ?? false,
              radiusKm: radiusKm,
              appState: appState,
            ),
          ),
          const SizedBox(height: 16),

          FadeInSlide(
            index: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radio, size: 16, color: AppColors.teal600),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.t('jobsNearYou', lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.teal200),
                      ),
                      child: Text(
                        '${nearbyJobs.length} Live',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal700,
                        ),
                      ),
                    ),
                  ],
                ),
                ScalePress(
                  onTap: onOpenMapClick,
                  child: Row(
                    children: [
                      const Icon(Icons.map, size: 14, color: AppColors.teal600),
                      const SizedBox(width: 4),
                      const Text('Map View',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Jobs list with staggered animations
          if (nearbyJobs.isEmpty)
            FadeInSlide(
              index: 2,
              child: EmptyState(
                icon: Icons.radar,
                title: 'No Jobs in Your Radius',
                message:
                    'Try increasing your notification radius or checking other skill categories in Settings!',
                iconColor: AppColors.teal600,
              ),
            )
          else
            StaggeredList(
              delayPerItem: const Duration(milliseconds: 60),
              children: nearbyJobs.asMap().entries.map((entry) {
                return FadeInSlide(
                  index: entry.key + 2,
                  child: _WorkerJobCard(
                    job: entry.value,
                    workerLoc: workerLoc,
                    hasApplied: appState.applications.any(
                      (a) => a.jobId == entry.value.id && a.workerProfileId == appState.workerProfile?.id,
                    ),
                    appState: appState,
                    onTap: () => onOpenJobDetails(entry.value),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ),
    );
  }
}

class _PresenceBanner extends StatefulWidget {
  final bool isOnline;
  final double radiusKm;
  final AppState appState;
  const _PresenceBanner({required this.isOnline, required this.radiusKm, required this.appState});

  @override
  State<_PresenceBanner> createState() => _PresenceBannerState();
}

class _PresenceBannerState extends State<_PresenceBanner> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.radiusKm;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.appState.language;
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.teal800, AppColors.teal900]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal700.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal900.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: widget.isOnline ? AppColors.emerald400 : AppColors.slate400,
                        shape: BoxShape.circle,
                        boxShadow: widget.isOnline
                            ? [BoxShadow(
                                color: AppColors.emerald400.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isOnline ? 'You are Online on Nearby Map' : 'You are Offline',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          widget.isOnline
                              ? 'Receiving job alerts within $_radius km radius in Lahore'
                              : 'Turn on to receive nearby employer requests',
                          style: const TextStyle(fontSize: 10, color: AppColors.teal100),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ScalePress(
                onTap: () => widget.appState.toggleWorkerOnline(!widget.isOnline),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isOnline ? AppColors.emerald400 : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.isOnline ? 'ONLINE' : 'GO ONLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: widget.isOnline ? AppColors.teal950 : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.teal700, thickness: 0.5),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${AppTranslations.t('notificationRadius', lang)}: ',
                  style: const TextStyle(fontSize: 10, color: AppColors.teal100)),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _radius > 20 ? AppColors.amber300 : AppColors.emerald400,
                ),
                child: Text('$_radius km'),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.amber400,
                    inactiveTrackColor: AppColors.teal950.withValues(alpha: 0.4),
                    thumbColor: AppColors.amber400,
                    overlayColor: AppColors.amber400.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 3,
                    max: 30,
                    value: _radius,
                    onChanged: (v) {
                      setState(() => _radius = v);
                      widget.appState.updateWorkerRadius(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerJobCard extends StatelessWidget {
  final Job job;
  final LocationPoint workerLoc;
  final bool hasApplied;
  final AppState appState;
  final VoidCallback onTap;

  const _WorkerJobCard({
    required this.job,
    required this.workerLoc,
    required this.hasApplied,
    required this.appState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = calculateDistanceKm(
      lat1: job.pinLocation.lat, lng1: job.pinLocation.lng,
      lat2: workerLoc.lat, lng2: workerLoc.lng,
    );
    final lang = appState.language;

    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.teal100,
          highlightColor: AppColors.teal50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.amber200),
                      ),
                      child: Text(job.urgency.name.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.amber700, letterSpacing: 0.3)),
                    ),
                    const SizedBox(width: 8),
                    Text('📍 ${formatDistance(distanceKm)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(job.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800, height: 1.3)),
                const SizedBox(height: 4),
                Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(job.pinLocation.address,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate600)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatPkr(job.budgetAmount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                        Text(job.budgetType.name,
                            style: const TextStyle(fontSize: 9, color: AppColors.slate400)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ScalePress(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 14, color: AppColors.slate600),
                              SizedBox(width: 6),
                              Text('Not Now',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ScalePress(
                        onTap: hasApplied ? null : () => appState.expressInterest(job.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: hasApplied ? AppColors.teal50 : AppColors.teal600,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: hasApplied
                                ? null
                                : [BoxShadow(
                                    color: AppColors.teal600.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))],
                            border: hasApplied ? Border.all(color: AppColors.teal200) : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 14,
                                  color: hasApplied ? AppColors.teal700 : Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                hasApplied ? 'Interest Sent' : AppTranslations.t('imInterested', lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasApplied ? AppColors.teal700 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
