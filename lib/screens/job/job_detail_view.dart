import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../utils/geo.dart';
import '../../models/job.dart';
import '../../models/application.dart';
import '../../models/profile.dart';
import '../../widgets/animations.dart';

class JobDetailView extends StatelessWidget {
  final AppState appState;
  final Job job;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenChat;

  const JobDetailView({
    super.key,
    required this.appState,
    required this.job,
    required this.onBack,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    final isEmployer = appState.activeProfileType == ProfileType.employer;
    final jobApps = appState.applications.where((a) => a.jobId == job.id).toList();

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.teal50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.teal200),
                              ),
                              child: Text('${job.urgency.name.toUpperCase()} Urgency',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.teal700, letterSpacing: 0.3)),
                            ),
                            const SizedBox(height: 8),
                            Text(job.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800, height: 1.3)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatPkr(job.budgetAmount),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal700)),
                          Text(job.budgetType.name,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Text(job.description,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate700, height: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.teal600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(job.pinLocation.address,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800)),
                      ),
                    ],
                  ),
                  if (job.aiExtractedSummary?.requiredSkills != null &&
                      job.aiExtractedSummary!.requiredSkills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.aiExtractedSummary!.requiredSkills.map((sk) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Text('✓ $sk',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // EMPLOYER VIEW: Interested Workers
          if (isEmployer) ..._buildEmployerView(lang, jobApps),

          // WORKER VIEW: Express Interest CTA
          if (!isEmployer) _buildWorkerView(lang),
        ],
      ),
    );
  }

  List<Widget> _buildEmployerView(LanguageOption lang, List<Application> jobApps) {
    return [
      FadeInSlide(
        index: 2,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.teal600),
            const SizedBox(width: 8),
            Text(AppTranslations.t('interestedWorkers', lang),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal200),
              ),
              child: Text('${jobApps.length}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal700)),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 40, color: AppColors.slate300),
                const SizedBox(height: 12),
                Text(AppTranslations.t('noWorkersInterestedYet', lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
              ],
            ),
          ),
        )
      else
        StaggeredList(
          delayPerItem: const Duration(milliseconds: 50),
          children: jobApps.asMap().entries.map((entry) {
            final app = entry.value;
            final workerData = appState.getPublicProfile(app.workerProfileId);
            if (workerData == null || workerData.workerDetails == null) {
              return const SizedBox.shrink();
            }
            final profile = workerData.profile;
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(profile.profilePhotoUrl, width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const CircleAvatar(radius: 22, child: Icon(Icons.person))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(profile.displayName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                                  if (profile.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, size: 14, color: AppColors.teal600),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 12, color: AppColors.amber500),
                                  const SizedBox(width: 2),
                                  Text('${details.averageRating}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber600)),
                                  const SizedBox(width: 6),
                                  Text('• ${details.totalJobsCompleted} jobs',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                                  const SizedBox(width: 6),
                                  Text('• ${formatDistance(distanceKm)}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (app.status == ApplicationStatus.hired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.teal600, borderRadius: BorderRadius.circular(10)),
                            child: const Text('HIRED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.teal200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(app.aiMatchNote ?? '⚡ High rating match nearby in Lahore.',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal900)),
                          ),
                        ],
                      ),
                    ),
                    if (app.message != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.maxFinite,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Text('"${app.message}"',
                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ScalePress(
                            onTap: () => onOpenChat(profile.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.teal200),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_outlined, size: 14, color: AppColors.teal600),
                                  SizedBox(width: 6),
                                  Text('Chat First',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ScalePress(
                            onTap: app.status == ApplicationStatus.hired
                                ? null
                                : () {
                                    appState.hireWorker(job.id, profile.id);
                                    onOpenChat(profile.id);
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: app.status == ApplicationStatus.hired ? AppColors.slate100 : AppColors.teal600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.work, size: 14,
                                      color: app.status == ApplicationStatus.hired ? AppColors.slate400 : Colors.white),
                                  const SizedBox(width: 6),
                                  Text(app.status == ApplicationStatus.hired ? 'Hired' : 'Hire Now',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: app.status == ApplicationStatus.hired ? AppColors.slate400 : Colors.white,
                                      )),
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
    ];
  }

  Widget _buildWorkerView(LanguageOption lang) {
    final hasApplied = appState.applications.any(
      (a) => a.jobId == job.id && a.workerProfileId == appState.workerProfile?.id,
    );

    return FadeInSlide(
      index: 3,
      child: SizedBox(
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: hasApplied ? null : () => appState.expressInterest(job.id),
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
