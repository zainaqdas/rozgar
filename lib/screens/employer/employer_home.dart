import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class EmployerHome extends StatelessWidget {
  final AppState appState;
  final VoidCallback onPostJobClick;
  final ValueChanged<Job> onOpenJobDetails;
  final VoidCallback onOpenMapClick;

  const EmployerHome({
    super.key,
    required this.appState,
    required this.onPostJobClick,
    required this.onOpenJobDetails,
    required this.onOpenMapClick,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    final myJobs = appState.getEmployerJobs();

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
          // Welcome Banner with fade-in
          FadeInSlide(
            index: 0,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal800, AppColors.teal900]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal700.withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(
                  color: AppColors.teal900.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Employer Workspace',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.teal200, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          'Assalam-o-Alaikum, ${appState.employerProfile?.displayName ?? 'Employer'}!',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text('Need a quick local job done in Lahore?',
                            style: TextStyle(fontSize: 12, color: AppColors.teal100)),
                      ],
                    ),
                  ),
                  ScalePress(
                    onTap: onPostJobClick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.teal900, weight: 3),
                          SizedBox(width: 4),
                          Text('Post Job',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Grid
          FadeInSlide(
            index: 1,
            child: Row(
              children: [
                Expanded(
                  child: ScalePress(
                    onTap: onPostJobClick,
                    child: _QuickActionCard(
                      emoji: '⚡',
                      title: AppTranslations.t('postJobCTA', lang),
                      subtitle: 'AI auto-fills category & budget',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScalePress(
                    onTap: onOpenMapClick,
                    child: _QuickActionCard(
                      emoji: '🗺️',
                      title: 'Explore Nearby Map',
                      subtitle: 'View active online workers',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Posted Jobs Header
          FadeInSlide(
            index: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: AppColors.teal600),
                    const SizedBox(width: 8),
                    const Text('My Posted Jobs',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(10)),
                      child: Text('${myJobs.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Job List with staggered animations
          if (myJobs.isEmpty)
            FadeInSlide(
              index: 3,
              child: EmptyState(
                icon: Icons.work_outline,
                title: 'No Jobs Posted Yet',
                message: 'Post your first job and nearby workers will respond within minutes.',
                actionLabel: 'Post a Job Now',
                onAction: onPostJobClick,
                iconColor: AppColors.teal600,
              ),
            )
          else
            StaggeredList(
              delayPerItem: const Duration(milliseconds: 60),
              children: myJobs.asMap().entries.map((entry) {
                return FadeInSlide(
                  index: entry.key + 3,
                  child: _JobCard(
                    job: entry.value,
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

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _QuickActionCard({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.teal50, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final AppState appState;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.appState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final jobApps = appState.applications.where((a) => a.jobId == job.id).toList();
    final statusColor = job.status == JobStatus.open
        ? AppColors.teal700
        : job.status == JobStatus.hired ? AppColors.amber700 : AppColors.slate600;
    final statusBg = job.status == JobStatus.open
        ? AppColors.teal50
        : job.status == JobStatus.hired ? AppColors.amber50 : AppColors.slate100;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800, height: 1.3)),
                          const SizedBox(height: 2),
                          Text(job.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(job.status.name.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.teal600),
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
        ),
      ),
    );
  }
}
