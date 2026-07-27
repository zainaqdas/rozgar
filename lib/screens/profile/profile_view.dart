import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../data/categories.dart';
import '../../models/profile.dart';
import '../../models/review.dart';

class ProfileView extends StatefulWidget {
  final AppState appState;

  const ProfileView({super.key, required this.appState});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _cnicController = TextEditingController(text: '35201-1234567-1');
  bool _isVerifying = false;
  bool _cnicSuccess = false;
  final _bioController = TextEditingController();
  bool _isAiBioLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController.text =
        widget.appState.workerDetails?.bio ?? '';
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final lang = state.language;
    final profile = state.activeProfile;
    final isWorker = state.activeProfileType == ProfileType.worker;
    final details = state.workerDetails;
    final profileReviews = state.reviews
        .where((r) => r.revieweeProfileId == profile?.id)
        .toList();

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
                    state.updateWorkerBio(newBio);
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
              state.setLanguage(
                lang == LanguageOption.en
                    ? LanguageOption.ur
                    : LanguageOption.en,
              );
            },
            onLogout: state.logout,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(
              profile.profilePhotoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const CircleAvatar(
                radius: 28,
                child: Icon(Icons.person, size: 28),
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
                    Expanded(
                      child: Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800,
                        ),
                      ),
                    ),
                    if (cnicVerified)
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.teal600),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.teal600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        profile.homeLocation.address,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWorker
                  ? AppColors.amber100
                  : AppColors.teal50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isWorker
                    ? AppColors.amber200
                    : AppColors.teal200,
              ),
            ),
            child: Text(
              isWorker ? 'WORKER' : 'EMPLOYER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: isWorker
                    ? AppColors.amber800
                    : AppColors.teal800,
              ),
            ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.t('profileCompletion', lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
              Text(
                '${pct.toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.slate200,
              valueColor: const AlwaysStoppedAnimation(
                  AppColors.teal600),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.t('completeProfilePrompt', lang),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Worker Bio & Skill Intro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              GestureDetector(
                onTap: onAiBio,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: isAiBioLoading
                          ? AppColors.slate400
                          : AppColors.amber600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAiBioLoading
                          ? 'Writing...'
                          : 'AI Bio Polish',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isAiBioLoading
                            ? AppColors.slate400
                            : AppColors.amber600,
                      ),
                    ),
                  ],
                ),
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
            child: Text(
              '"$bio"',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: AppColors.slate700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        '${details.yearsExperience} Years',
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
                    border: Border.all(
                        color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                          const Icon(Icons.star,
                              size: 12,
                              color: AppColors.amber500),
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
              Icon(Icons.verified_user,
                  size: 20, color: AppColors.teal600),
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
                  Icon(Icons.check_circle,
                      size: 16, color: AppColors.teal600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CNIC Verified Citizen. Verified trust badge active on profile.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'Submit your 13-digit Pakistani CNIC to earn a verified citizen badge.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cnicController,
                    decoration: const InputDecoration(
                      hintText: '35201-XXXXXXX-X',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isVerifying ? null : onVerify,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.teal600,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      isVerifying
                          ? 'Verifying...'
                          : 'Submit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
              const Icon(Icons.star,
                  size: 16, color: AppColors.amber500),
              const SizedBox(width: 8),
              Text(
                '${AppTranslations.t('reviews', lang)} (${reviews.length})',
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
            const Text(
              'No reviews received yet for this active profile.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            )
          else
            ...reviews.map((rev) => Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppColors.slate100),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Verified Client',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate800,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12,
                                  color: AppColors.amber500),
                              const SizedBox(width: 2),
                              Text(
                                '${rev.rating}.0',
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
                      const SizedBox(height: 4),
                      Text(
                        '"${rev.comment}"',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
      padding: const EdgeInsets.all(8),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: color ?? AppColors.teal600),
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
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
