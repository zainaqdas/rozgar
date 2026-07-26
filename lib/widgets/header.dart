import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

class RozgarHeader extends StatelessWidget {
  final AppState appState;
  final VoidCallback onOpenNotifications;

  const RozgarHeader({
    super.key,
    required this.appState,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        appState.notifications.where((n) => !n.isRead).length;
    final lang = appState.language;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.slate200),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // App Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal600,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal600.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'ر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // App Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppTranslations.t('appName', lang),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '| ہنر مند',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.teal50,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: AppColors.teal200),
                          ),
                          child: const Text(
                            'PKR 🇵🇰',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'LAHORE • LOCAL SERVICES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate400,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),


              // Profile Switcher Badge
              _ProfileBadge(appState: appState),

              const SizedBox(width: 6),

              // Language Toggle
              _LanguageButton(
                lang: lang,
                onTap: () {
                  appState.setLanguage(
                    lang == LanguageOption.en
                        ? LanguageOption.ur
                        : LanguageOption.en,
                  );
                },
              ),

              const SizedBox(width: 6),

              // Notification Bell
              _NotificationBell(
                unreadCount: unreadCount,
                onTap: onOpenNotifications,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final AppState appState;
  const _ProfileBadge({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isEmployer = appState.activeProfileType == ProfileType.employer;
    final lang = appState.language;

    return GestureDetector(
      onTap: () => _showProfileSwitcher(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEmployer ? Icons.work_outline : Icons.construction,
              size: 14,
              color: isEmployer ? AppColors.teal600 : AppColors.amber600,
            ),
            const SizedBox(width: 4),
            Text(
              isEmployer
                  ? AppTranslations.t('employer', lang)
                  : AppTranslations.t('worker', lang),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isEmployer
                    ? AppColors.teal700
                    : AppColors.amber700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down,
                size: 12, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  void _showProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProfileSwitcherSheet(appState: appState),
    );
  }
}

class _ProfileSwitcherSheet extends StatelessWidget {
  final AppState appState;
  const _ProfileSwitcherSheet({required this.appState});

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz,
                  size: 20, color: AppColors.teal600),
              const SizedBox(width: 8),
              Text(
                AppTranslations.t('switchProfile', lang),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your Employer profile and Worker profile maintain completely separate job histories, ratings, and settings under the same login.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),

          // Employer Option
          _ProfileOptionTile(
            icon: Icons.work_outline,
            iconBgColor: AppColors.teal100,
            iconColor: AppColors.teal700,
            title: 'Employer Profile',
            subtitle:
                appState.employerProfile?.displayName ?? 'Post jobs & hire nearby workers',
            isActive: appState.activeProfileType == ProfileType.employer,
            activeColor: AppColors.teal600,
            onTap: () {
              appState.switchProfile(ProfileType.employer);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),

          // Worker Option
          _ProfileOptionTile(
            icon: Icons.construction,
            iconBgColor: AppColors.amber100,
            iconColor: AppColors.amber700,
            title: 'Worker Profile',
            subtitle:
                appState.workerProfile?.displayName ?? 'Receive job alerts & earn daily',
            isActive: appState.activeProfileType == ProfileType.worker,
            activeColor: AppColors.amber500,
            onTap: () {
              appState.switchProfile(ProfileType.worker);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal50.withValues(alpha: 0.8)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : AppColors.slate200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, size: 20, color: activeColor),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final LanguageOption lang;
  final VoidCallback onTap;
  const _LanguageButton({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Center(
          child: Text(
            lang == LanguageOption.en ? 'اردو' : 'EN',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const _NotificationBell(
      {required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child:
                  Icon(Icons.notifications_outlined, size: 18, color: AppColors.slate700),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.rose500,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
