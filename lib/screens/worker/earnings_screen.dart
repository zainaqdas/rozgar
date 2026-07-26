import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../models/application.dart';

/// Earnings & Job History screen for workers (Screen #8 worker tab: "Earnings/History").
/// Shows completed jobs, earnings stats, and job history breakdown.
class EarningsScreen extends StatefulWidget {
  final AppState appState;

  const EarningsScreen({super.key, required this.appState});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final workerProfile = state.workerProfile;
    final details = state.workerDetails;

    // Worker's completed jobs (jobs where they were hired)
    final completedJobs = state.jobs
        .where((j) =>
            j.status == JobStatus.completed &&
            state.applications.any((a) =>
                a.jobId == j.id &&
                a.workerProfileId == workerProfile?.id &&
                a.status == ApplicationStatus.hired))
        .toList();

    // All jobs the worker applied to
    final workerApps = state.applications
        .where((a) => a.workerProfileId == workerProfile?.id)
        .toList();

    // All hired jobs (in progress or completed)
    final hiredJobs = state.jobs
        .where((j) =>
            j.status == JobStatus.hired &&
            j.hiredWorkerProfileId == workerProfile?.id)
        .toList();

    final totalEarnings = completedJobs.fold<double>(
      0,
      (sum, job) => sum + job.budgetAmount,
    );

    // Filter
    List<Job> filteredJobs;
    switch (_filterStatus) {
      case 'completed':
        filteredJobs = completedJobs;
        break;
      case 'in_progress':
        filteredJobs = hiredJobs;
        break;
      case 'all':
      default:
        filteredJobs = [...hiredJobs, ...completedJobs];
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Summary Card
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal800, AppColors.teal900],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.teal700.withValues(alpha: 0.5)),
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
                const Text(
                  'Total Earnings',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal200,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPkr(totalEarnings),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _EarningStat(
                      value: '${details?.totalJobsCompleted ?? completedJobs.length}',
                      label: 'Jobs Done',
                    ),
                    _EarningStat(
                      value: '${details?.averageRating ?? 0}',
                      label: 'Rating',
                    ),
                    _EarningStat(
                      value: '${details?.responseTimeAvgMinutes ?? 0}m',
                      label: 'Avg Response',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Jobs',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Text(
                        '${hiredJobs.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.teal600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Applications',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Text(
                        '${workerApps.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.teal600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Completed',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Text(
                        '${completedJobs.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.teal600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Job History Header with Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history,
                      size: 16, color: AppColors.teal600),
                  SizedBox(width: 8),
                  Text('Job History',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800)),
                ],
              ),
              Row(
                children: ['all', 'in_progress', 'completed'].map((f) {
                  final isActive = _filterStatus == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = f),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.teal600
                            : AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        f == 'all'
                            ? 'All'
                            : f == 'in_progress'
                                ? 'Active'
                                : 'Done',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : AppColors.slate600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Job History List
          if (filteredJobs.isEmpty)
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Center(
                child: Text(
                  'No jobs in this category yet.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            )
          else
            ...filteredJobs.map((job) => Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      // Status indicator
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: job.status == JobStatus.completed
                              ? AppColors.emerald400
                              : AppColors.amber400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  job.pinLocation.address,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.slate500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo(job.createdAt),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPkr(job.budgetAmount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate800,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: job.status == JobStatus.completed
                                  ? AppColors.teal50
                                  : AppColors.amber50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.status == JobStatus.completed
                                  ? 'Done'
                                  : 'Active',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: job.status == JobStatus.completed
                                    ? AppColors.teal700
                                    : AppColors.amber700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String value;
  final String label;

  const _EarningStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.teal200,
          ),
        ),
      ],
    );
  }
}
