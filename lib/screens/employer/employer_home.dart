import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class EmployerHome extends ConsumerWidget {
  final VoidCallback onPostJobClick;
  final ValueChanged<Job> onOpenJobDetails;
  final VoidCallback onOpenMapClick;

  const EmployerHome({
    super.key,
    required this.onPostJobClick,
    required this.onOpenJobDetails,
    required this.onOpenMapClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final jobNotifier = ref.watch(jobProvider);
    final profile = ref.watch(profileProvider);
    final employerId = profile.employerProfile?.id;

    final myJobs = employerId != null
        ? jobNotifier.jobs.where((j) => j.employerProfileId == employerId).toList()
        : <Job>[];

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
          // Welcome Banner with fade-in
          FadeInSlide(
            index: 0,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal800, AppColors.teal900]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.t('postJobCTA', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.t('appTagline', lang),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.teal200),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onPostJobClick,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline, size: 16, color: AppColors.teal700),
                                const SizedBox(width: 6),
                                Text(
                                  AppTranslations.t('postJobCTA', lang),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onOpenMapClick,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.teal700,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.teal600),
                          ),
                          child: const Icon(Icons.map_outlined, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // My Jobs Header
          FadeInSlide(
            index: 1,
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 18, color: AppColors.teal600),
                const SizedBox(width: 8),
                Text(
                  'My Jobs (${myJobs.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Jobs List
          if (myJobs.isEmpty)
            FadeInSlide(
              index: 2,
              child: EmptyState(
                icon: Icons.work_outline,
                title: AppTranslations.t('noJobsFound', lang),
                message: AppTranslations.t('postJobCTA', lang),
                actionLabel: AppTranslations.t('postJobCTA', lang),
                onAction: onPostJobClick,
                lang: lang,
              ),
            )
          else
            ...myJobs.asMap().entries.map((entry) {
              final index = entry.key;
              final job = entry.value;
              final jobApps = jobNotifier.applications.where((a) => a.jobId == job.id).toList();
              return FadeInSlide(
                index: index + 2,
                child: _JobCard(
                  job: job,
                  jobApps: jobApps,
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

class _JobCard extends StatelessWidget {
  final Job job;
  final List<dynamic> jobApps;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.jobApps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: job.status == JobStatus.open ? AppColors.teal50 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: job.status == JobStatus.open ? AppColors.teal200 : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    job.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: job.status == JobStatus.open ? AppColors.teal700 : AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.slate400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.pinLocation.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                ),
                const SizedBox(width: 12),
                Text(formatPkr(job.budgetAmount),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.teal200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 12, color: AppColors.teal600),
                      const SizedBox(width: 4),
                      Text('${jobApps.length} Interested',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal800)),
                    ],
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
