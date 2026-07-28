import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../models/application.dart';

/// Earnings & Job History screen for workers (Screen #8 worker tab: "Earnings/History").
/// Shows completed jobs, earnings stats, and job history breakdown.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobProvider);
    final profile = ref.watch(profileProvider);
    final workerProfile = profile.workerProfile;
    final details = profile.workerDetails;

    // Worker's completed jobs (jobs where they were hired)
    final completedJobs = jobs.jobs
        .where((j) =>
            j.status == JobStatus.completed &&
            jobs.applications.any((a) =>
                a.jobId == j.id &&
                a.workerProfileId == workerProfile?.id &&
                a.status == ApplicationStatus.hired))
        .toList();

    // All jobs the worker applied to
    final workerApps = jobs.applications
        .where((a) => a.workerProfileId == workerProfile?.id)
        .toList();

    // All hired jobs (in progress or completed)
    final hiredJobs = jobs.jobs
        .where((j) =>
            j.status == JobStatus.hired &&
            j.hiredWorkerProfileId == workerProfile?.id)
        .toList();

    // Filtered list
    final filteredJobs = _filterStatus == 'all'
        ? [...hiredJobs, ...completedJobs]
        : _filterStatus == 'active'
            ? hiredJobs
            : completedJobs;

    // Stats
    final totalEarnings = completedJobs.fold<double>(
        0, (sum, j) => sum + j.budgetAmount);
    final avgRating = details?.averageRating ?? 5.0;
    final totalCompleted = details?.totalJobsCompleted ?? completedJobs.length;

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
                  colors: [AppColors.teal700, AppColors.teal900]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal200),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPkr(totalEarnings),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _EarningStat(
                        value: '$totalCompleted', label: 'Jobs Done'),
                    const SizedBox(width: 24),
                    _EarningStat(
                        value: avgRating.toStringAsFixed(1),
                        label: 'Avg Rating'),
                    const SizedBox(width: 24),
                    _EarningStat(
                        value: '${workerApps.length}', label: 'Applications'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filter Chips
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isActive: _filterStatus == 'all',
                onTap: () => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Active',
                isActive: _filterStatus == 'active',
                onTap: () => setState(() => _filterStatus = 'active'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Completed',
                isActive: _filterStatus == 'completed',
                onTap: () => setState(() => _filterStatus = 'completed'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Job History List
          if (filteredJobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.work_history,
                        size: 48, color: AppColors.slate300),
                    SizedBox(height: 12),
                    Text(
                      'No jobs found',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Jobs you complete will appear here.',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredJobs.map((job) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: job.status == JobStatus.completed
                                  ? AppColors.teal50
                                  : AppColors.amber50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: job.status == JobStatus.completed
                                      ? AppColors.teal200
                                      : AppColors.amber200),
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.pinLocation.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate500),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatPkr(job.budgetAmount),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate800),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.teal600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? AppColors.teal600 : AppColors.slate200),
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
