import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../data/categories.dart';
import '../../models/profile.dart';
import '../../models/review.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _cnicController = TextEditingController(text: '35201-1234567-1');
  bool _isVerifying = false;
  bool _cnicSuccess = false;
  final _bioController = TextEditingController();
  bool _isAiBioLoading = false;
  bool _bioInitialized = false;

  @override
  void dispose() {
    _cnicController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileNotifier = ref.watch(profileProvider);
    final lang = settings.language;
    final profile = profileNotifier.activeProfile;
    final isWorker = profileNotifier.activeProfileType == ProfileType.worker;
    final details = profileNotifier.workerDetails;
    final profileReviews = profileNotifier.reviews
        .where((r) => r.revieweeProfileId == profile?.id)
        .toList();

    // Initialize bio controller once when worker details are available
    if (!_bioInitialized && details != null) {
      _bioController.text = details.bio;
      _bioInitialized = true;
    }

    if (profile == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          _ProfileHeaderCard(
            profile: profile,
            isWorker: isWorker,
            cnicVerified: _cnicSuccess || profile.isVerified,
          ),
          const SizedBox(height: 16),

          // Profile Completion Meter
          _CompletionMeter(
            pct: profile.onboardingCompletionPct,
            lang: lang,
          ),
          const SizedBox(height: 16),

          // Worker Bio Section
          if (isWorker && details != null) ...[
            _BioSection(
              bio: _bioController.text,
              isAiBioLoading: _isAiBioLoading,
              details: details,
              onBioChanged: (v) => _bioController.text = v,
              onAiBio: () async {
                setState(() => _isAiBioLoading = true);
                try {
                  final categoryName = seededCategories
                      .where((c) => c.id == details.categoryIds.firstOrNull)
                      .firstOrNull
                      ?.nameEn ?? 'Services';
                  final result = await AIService.generateBio(
                    _bioController.text.isEmpty ? 'Local technician' : _bioController.text,
                    categoryName,
                  );
                  if (!mounted) return;
                  final newBio = result['bio'] as String? ?? '';
                  if (newBio.isNotEmpty) {
                    _bioController.text = newBio;
                    ref.read(profileProvider.notifier).updateWorkerBio(newBio);
                  }
                } catch (e) {
                  debugPrint('AI bio generation failed: $e');
                }
                if (mounted) setState(() => _isAiBioLoading = false);
              },
            ),
            const SizedBox(height: 16),
          ],

          // CNIC Verification
          _CnicSection(
            cnicController: _cnicController,
            isVerifying: _isVerifying,
            isVerified: _cnicSuccess || profile.isVerified,
            onVerify: () {
              setState(() => _isVerifying = true);
              Future.delayed(
                  const Duration(milliseconds: 1200), () {
                if (mounted) {
                  setState(() {
                    _isVerifying = false;
                    _cnicSuccess = true;
                  });
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // Reviews
          _ReviewsSection(
            reviews: profileReviews,
            lang: lang,
          ),
          const SizedBox(height: 16),

          // Settings & Logout
          _SettingsSection(
            lang: lang,
            onLanguageToggle: () {
              ref.read(settingsProvider.notifier).setLanguage(
                lang == LanguageOption.en
                    ? LanguageOption.ur
                    : LanguageOption.en,
              );
            },
            onLogout: () {
              ref.read(coordinatorProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final Profile profile;
  final bool isWorker;
  final bool cnicVerified;

  const _ProfileHeaderCard({
    required this.profile,
    required this.isWorker,
    required this.cnicVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWorker
              ? [AppColors.amber600, AppColors.amber800]
              : [AppColors.teal700, AppColors.teal900],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (cnicVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 18, color: Colors.white),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isWorker ? 'Worker' : 'Employer',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                profile.city,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionMeter extends StatelessWidget {
  final double pct;
  final LanguageOption lang;

  const _CompletionMeter({
    required this.pct,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.t('activeProfile', lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
              Text(
                '${pct.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  final String bio;
  final bool isAiBioLoading;
  final WorkerDetails details;
  final ValueChanged<String> onBioChanged;
  final VoidCallback onAiBio;

  const _BioSection({
    required this.bio,
    required this.isAiBioLoading,
    required this.details,
    required this.onBioChanged,
    required this.onAiBio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.edit_note, size: 20, color: AppColors.teal600),
              const SizedBox(width: 8),
              const Text(
                'Professional Bio',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isAiBioLoading ? null : onAiBio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAiBioLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else
                        const Icon(Icons.auto_awesome, size: 12, color: AppColors.teal600),
                      const SizedBox(width: 4),
                      const Text(
                        'AI Write',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: bio),
            onChanged: onBioChanged,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your skills and experience...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.teal600),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.slate700),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Experience',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${details.yearsExperience} yrs',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg Rating',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.amber500),
                          const SizedBox(width: 2),
                          Text(
                            '${details.averageRating} (${details.totalJobsCompleted} jobs)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.amber600,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CnicSection extends StatelessWidget {
  final TextEditingController cnicController;
  final bool isVerifying;
  final bool isVerified;
  final VoidCallback onVerify;

  const _CnicSection({
    required this.cnicController,
    required this.isVerifying,
    required this.isVerified,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.verified_user, size: 20, color: AppColors.teal600),
              SizedBox(width: 8),
              Text(
                'NADRA / CNIC Identity Verification',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isVerified)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: AppColors.teal600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Identity Verified — You are a trusted member of the Rozgar community.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: cnicController,
              decoration: InputDecoration(
                hintText: 'XXXXX-XXXXXXX-X',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal600),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.slate700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              child: GestureDetector(
                onTap: isVerifying ? null : onVerify,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isVerifying ? AppColors.slate300 : AppColors.teal600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify with NADRA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final LanguageOption lang;

  const _ReviewsSection({
    required this.reviews,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.reviews_outlined, size: 20, color: AppColors.amber500),
              const SizedBox(width: 8),
              Text(
                'Reviews (${reviews.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 12, color: AppColors.slate400),
                ),
              ),
            )
          else
            ...reviews.take(3).map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 12,
                          color: AppColors.amber500,
                        )),
                        const Spacer(),
                        Text(
                          '${review.rating}.0',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final LanguageOption lang;
  final VoidCallback onLanguageToggle;
  final VoidCallback onLogout;

  const _SettingsSection({
    required this.lang,
    required this.onLanguageToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language,
            label: 'Language: ${lang == LanguageOption.en ? 'English (تخلیق)' : 'اردو'}',
            onTap: onLanguageToggle,
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Log Out',
            color: AppColors.rose500,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? AppColors.teal600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.slate700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
