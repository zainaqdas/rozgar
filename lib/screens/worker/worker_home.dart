import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../utils/geo.dart';
import '../../models/job.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class WorkerHome extends ConsumerWidget {
  final ValueChanged<Job> onOpenJobDetails;
  final VoidCallback onOpenMapClick;

  const WorkerHome({
    super.key,
    required this.onOpenJobDetails,
    required this.onOpenMapClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final profile = ref.watch(profileProvider);
    final jobNotifier = ref.watch(jobProvider);
    final details = profile.workerDetails;
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
    final nearbyJobs = jobNotifier.getJobsNearWorker(
      workerLocation: workerLoc,
      radiusKm: radiusKm,
      categoryIds: categoryIds,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(coordinatorProvider.notifier).refreshFromSupabase(),
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
              details: details,
            ),
          ),
          const SizedBox(height: 16),

          // Nearby Jobs Header
          FadeInSlide(
            index: 1,
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 18, color: AppColors.teal600),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.t('jobsNearYou', lang),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onOpenMapClick,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.teal50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 12, color: AppColors.teal700),
                        SizedBox(width: 4),
                        Text('Map', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Jobs List
          if (nearbyJobs.isEmpty)
            FadeInSlide(
              index: 2,
              child: EmptyState(
                icon: Icons.work_outline,
                title: AppTranslations.t('noJobsFound', lang),
                message: AppTranslations.t('checkBackLater', lang),
                lang: lang,
              ),
            )
          else
            ...nearbyJobs.asMap().entries.map((entry) {
              final index = entry.key;
              final job = entry.value;
              final hasApplied = jobNotifier.applications.any(
                (a) => a.jobId == job.id && a.workerProfileId == profile.workerProfile?.id,
              );
              return FadeInSlide(
                index: index + 2,
                child: _JobAlertCard(
                  job: job,
                  hasApplied: hasApplied,
                  lang: lang,
                  onTap: () => onOpenJobDetails(job),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }
}

class _PresenceBanner extends ConsumerWidget {
  final bool isOnline;
  final dynamic details;

  const _PresenceBanner({
    required this.isOnline,
    this.details,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [AppColors.teal700, AppColors.teal900]
              : [AppColors.slate600, AppColors.slate800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.emerald400 : AppColors.slate400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'You are Online & Visible' : 'You are Offline',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(profileProvider.notifier).toggleWorkerOnline(!isOnline),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOnline ? 'Go Offline' : 'Go Online',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Radius slider
          Row(
            children: [
              const Icon(Icons.radar, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'Alert Radius: ${(details?.notificationRadiusKm ?? 15).toInt()} km',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: (details?.notificationRadiusKm ?? 15).clamp(1, 50),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (v) => ref.read(profileProvider.notifier).updateWorkerRadius(v),
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

class _JobAlertCard extends ConsumerWidget {
  final Job job;
  final bool hasApplied;
  final LanguageOption lang;
  final VoidCallback onTap;

  const _JobAlertCard({
    required this.job,
    required this.hasApplied,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = calculateDistanceKm(
      lat1: job.pinLocation.lat,
      lng1: job.pinLocation.lng,
      lat2: ref.read(profileProvider).workerDetails?.currentLocation.lat ?? 31.5204,
      lng2: ref.read(profileProvider).workerDetails?.currentLocation.lng ?? 74.3587,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Urgency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: job.urgency == JobUrgency.instant
                        ? AppColors.rose50
                        : job.urgency == JobUrgency.today
                            ? AppColors.amber50
                            : AppColors.slate100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: job.urgency == JobUrgency.instant
                          ? AppColors.rose200
                          : job.urgency == JobUrgency.today
                              ? AppColors.amber200
                              : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    job.urgency == JobUrgency.instant
                        ? 'URGENT'
                        : job.urgency == JobUrgency.today
                            ? 'TODAY'
                            : 'SCHEDULED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: job.urgency == JobUrgency.instant
                          ? AppColors.rose500
                          : job.urgency == JobUrgency.today
                              ? AppColors.amber700
                              : AppColors.slate500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Location + distance
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.slate400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.pinLocation.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDistance(distance),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Budget + Apply button
            Row(
              children: [
                Text(
                  formatPkr(job.budgetAmount),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.slate800),
                ),
                const SizedBox(width: 4),
                Text(
                  job.budgetType == BudgetType.hourly ? '/hr' : job.budgetType == BudgetType.negotiable ? '(neg.)' : '',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate400),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: hasApplied
                      ? null
                      : () {
                          final workerProfile = ref.read(profileProvider).workerProfile;
                          if (workerProfile != null) {
                            ref.read(jobProvider.notifier).expressInterest(
                              job.id,
                              workerProfileId: workerProfile.id,
                              workerDisplayName: workerProfile.displayName,
                            );
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
