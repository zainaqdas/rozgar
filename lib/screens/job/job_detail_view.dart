import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../utils/geo.dart';
import '../../models/job.dart';
import '../../models/application.dart';
import '../../models/profile.dart';
import '../../widgets/animations.dart';

class JobDetailView extends ConsumerWidget {
  final Job job;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenChat;

  const JobDetailView({
    super.key,
    required this.job,
    required this.onBack,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final profile = ref.watch(profileProvider);
    final jobNotifier = ref.watch(jobProvider);
    final isEmployer = profile.activeProfileType == ProfileType.employer;
    final jobApps = jobNotifier.applications.where((a) => a.jobId == job.id).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          FadeInSlide(
            index: 0,
            child: Row(
              children: [
                ScalePress(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: const Icon(Icons.arrow_back, size: 16, color: AppColors.slate700),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.t('jobDetails', lang),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                    Text('ID: #${job.id}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Job Overview Card
          FadeInSlide(
            index: 1,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: job.status == JobStatus.open ? AppColors.teal700 : AppColors.slate500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    job.description,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate600, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // Details grid
                  Row(
                    children: [
                      _DetailChip(
                        icon: Icons.location_on_outlined,
                        label: job.pinLocation.address,
                      ),
                      const SizedBox(width: 8),
                      _DetailChip(
                        icon: Icons.attach_money,
                        label: formatPkr(job.budgetAmount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DetailChip(
                        icon: Icons.schedule,
                        label: job.urgency == JobUrgency.instant
                            ? 'URGENT'
                            : job.urgency == JobUrgency.today
                                ? 'Today'
                                : 'Scheduled',
                      ),
                      const SizedBox(width: 8),
                      _DetailChip(
                        icon: Icons.category_outlined,
                        label: job.categoryId,
                      ),
                    ],
                  ),
                  if (job.aiExtractedSummary != null &&
                      job.aiExtractedSummary!.requiredSkills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.aiExtractedSummary!.requiredSkills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.amber50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.amber200),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.amber700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Employer view: Applicants list
          if (isEmployer) ...[
            FadeInSlide(
              index: 2,
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 18, color: AppColors.teal600),
                  const SizedBox(width: 8),
                  Text(
                    'Applicants (${jobApps.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (jobApps.isEmpty)
              FadeInSlide(
                index: 3,
                child: Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.hourglass_empty, size: 32, color: AppColors.slate300),
                      SizedBox(height: 8),
                      Text(
                        'No applicants yet',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nearby workers have been notified. Applicants will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              )
            else
              StaggeredList(
                delayPerItem: const Duration(milliseconds: 50),
                children: jobApps.asMap().entries.map((entry) {
                  final app = entry.value;
                  final workerNotifier = ref.read(workerProvider);
                  final workerData = workerNotifier.getPublicProfile(
                    app.workerProfileId,
                    profile.workerProfile,
                    profile.workerDetails,
                  );
                  if (workerData == null || workerData.workerDetails == null) {
                    return const SizedBox.shrink();
                  }
                  final workerProfile = workerData.profile;
                  final details = workerData.workerDetails!;
                  final distanceKm = calculateDistanceKm(
                    lat1: job.pinLocation.lat, lng1: job.pinLocation.lng,
                    lat2: details.currentLocation.lat, lng2: details.currentLocation.lng,
                  );

                  return FadeInSlide(
                    index: entry.key + 3,
                    child: Container(
                      width: double.maxFinite,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.amber50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.amber200),
                                ),
                                child: Center(
                                  child: Text(
                                    workerProfile.displayName.isNotEmpty
                                        ? workerProfile.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.amber700),
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
                                          workerProfile.displayName,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800),
                                        ),
                                        if (workerProfile.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 14, color: AppColors.teal600),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 12, color: AppColors.amber500),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${details.averageRating}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${details.totalJobsCompleted} jobs',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formatDistance(distanceKm),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.teal600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (app.message != null && app.message!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.maxFinite,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.slate100),
                              ),
                              child: Text(
                                '"${app.message}"',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: AppColors.slate600, height: 1.3),
                              ),
                            ),
                          ],
                          if (app.aiMatchNote != null && app.aiMatchNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.maxFinite,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.teal50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.teal100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      app.aiMatchNote!,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal800, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onOpenChat(workerProfile.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal600,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: app.status == ApplicationStatus.hired
                                      ? null
                                      : () {
                                          final employerId = profile.employerProfile?.id;
                                          if (employerId != null) {
                                            ref.read(coordinatorProvider.notifier).hireWorker(
                                              jobId: job.id,
                                              workerProfileId: workerProfile.id,
                                              employerProfileId: employerId,
                                            );
                                          }
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: app.status == ApplicationStatus.hired
                                          ? AppColors.teal50
                                          : AppColors.emerald400,
                                      borderRadius: BorderRadius.circular(10),
                                      border: app.status == ApplicationStatus.hired
                                          ? Border.all(color: AppColors.teal200)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          app.status == ApplicationStatus.hired
                                              ? Icons.check_circle
                                              : Icons.work,
                                          size: 14,
                                          color: app.status == ApplicationStatus.hired
                                              ? AppColors.teal700
                                              : AppColors.teal950,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          app.status == ApplicationStatus.hired ? 'Hired' : 'Hire',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: app.status == ApplicationStatus.hired
                                                ? AppColors.teal700
                                                : AppColors.teal950,
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
                  );
                }).toList(),
              ),
          ],

          // Worker view: Apply button
          if (!isEmployer)
            _buildWorkerView(context, ref, lang),
        ],
      ),
    );
  }

  Widget _buildWorkerView(BuildContext context, WidgetRef ref, LanguageOption lang) {
    final jobNotifier = ref.watch(jobProvider);
    final profile = ref.watch(profileProvider);
    final hasApplied = jobNotifier.applications.any(
      (a) => a.jobId == job.id && a.workerProfileId == profile.workerProfile?.id,
    );

    return FadeInSlide(
      index: 3,
      child: SizedBox(
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: hasApplied
              ? null
              : () {
                  final workerProfile = profile.workerProfile;
                  if (workerProfile != null) {
                    ref.read(jobProvider.notifier).expressInterest(
                      job.id,
                      workerProfileId: workerProfile.id,
                      workerDisplayName: workerProfile.displayName,
                    );
                  }
                },
          style: hasApplied
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal50,
                  foregroundColor: AppColors.teal800,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.teal200),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 18,
                  color: hasApplied ? AppColors.teal700 : Colors.white),
              const SizedBox(width: 8),
              Text(hasApplied ? 'Interest Sent to Employer' : AppTranslations.t('imInterested', lang)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
