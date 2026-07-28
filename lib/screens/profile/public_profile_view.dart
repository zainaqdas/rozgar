import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../data/categories.dart';
import '../../models/category.dart';
import '../../models/profile.dart';
import '../../widgets/animations.dart';

class PublicProfileView extends ConsumerWidget {
  final Profile profile;
  final WorkerDetails? workerDetails;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenChat;
  final VoidCallback? onHire;

  const PublicProfileView({
    super.key,
    required this.profile,
    this.workerDetails,
    required this.onBack,
    required this.onOpenChat,
    this.onHire,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final wd = workerDetails;
    if (wd == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Worker details not available.',
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
        ),
      );
    }
    final profileReviews = ref.watch(profileProvider).reviews
        .where((r) => r.revieweeProfileId == profile.id)
        .toList();
    final categories = wd.categoryIds
        .map((id) => seededCategories.where((c) => c.id == id).firstOrNull)
        .where((c) => c != null)
        .cast<Category>()
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          FadeInSlide(
            index: 0,
            child: Row(
              children: [
                GestureDetector(
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
                const Text('Worker Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Profile Card
          FadeInSlide(
            index: 1,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(profile.profilePhotoUrl, width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40))),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(profile.displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate800),
                            textAlign: TextAlign.center),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 20, color: AppColors.teal600),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: categories
                        .map((cat) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.amber50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.amber200),
                              ),
                              child: Text(cat.nameEn,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber800)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(icon: Icons.star, value: wd.averageRating.toString(), label: 'Rating', iconColor: AppColors.amber500),
                        _StatItem(icon: Icons.work, value: '${wd.totalJobsCompleted}', label: 'Jobs Done', iconColor: AppColors.teal600),
                        _StatItem(icon: Icons.timer, value: '${wd.responseTimeAvgMinutes}m', label: 'Response', iconColor: AppColors.teal600),
                        _StatItem(icon: Icons.speed, value: '${wd.yearsExperience}y', label: 'Exp', iconColor: AppColors.teal600),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onOpenChat(profile.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.teal600,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.teal600.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.chat, size: 16, color: Colors.white), SizedBox(width: 6), Text('Send Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onHire,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.teal200),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_circle_outline, size: 16, color: AppColors.teal600), SizedBox(width: 6), Text('Invite to Job', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal800))],
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
          const SizedBox(height: 16),

          // Bio Section
          FadeInSlide(
            index: 2,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                  const SizedBox(height: 8),
                  Text(wd.bio, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate700, height: 1.6)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.teal600),
                      const SizedBox(width: 4),
                      Expanded(child: Text(profile.homeLocation.address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 14, color: AppColors.teal600),
                      const SizedBox(width: 4),
                      Text(wd.rateNote, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Portfolio Section
          if (wd.portfolioMedia.isNotEmpty) ...[
            FadeInSlide(
              index: 3,
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portfolio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: wd.portfolioMedia.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(wd.portfolioMedia[i], width: 100, height: 100, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                  width: 100, height: 100, color: AppColors.slate100,
                                  child: const Icon(Icons.image, color: AppColors.slate400))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reviews Section
          FadeInSlide(
            index: 4,
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.amber500),
                      const SizedBox(width: 8),
                      Text('${AppTranslations.t('reviews', lang)} (${profileReviews.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (profileReviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No reviews yet for this worker.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                      ),
                    )
                  else
                    ...profileReviews.map((rev) => Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.slate100))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Verified Client',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                                  Row(
                                    children: List.generate(5, (i) => Icon(i < rev.rating ? Icons.star : Icons.star_border, size: 12, color: AppColors.amber500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('"${rev.comment}"',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: AppColors.slate700, height: 1.4)),
                              const SizedBox(height: 4),
                              Text(timeAgo(rev.createdAt), style: const TextStyle(fontSize: 9, color: AppColors.slate400)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  const _StatItem({required this.icon, required this.value, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.slate500)),
      ],
    );
  }
}
