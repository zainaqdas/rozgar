import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import '../models/profile.dart';

class RozgarBottomNav extends ConsumerWidget {
  final AppView activeTab;
  final List<AppView> tabs;
  final ValueChanged<AppView> onTabChange;

  const RozgarBottomNav({
    super.key,
    required this.activeTab,
    required this.tabs,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final chat = ref.watch(chatProvider);
    final profile = ref.watch(profileProvider);
    final totalUnread = chat.conversations.fold<int>(
      0,
      (acc, c) =>
          acc +
          (profile.activeProfileType == ProfileType.employer
              ? c.unreadCountEmployer
              : c.unreadCountWorker),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.slate200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildTabItems(lang, totalUnread),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabItems(LanguageOption lang, int totalUnread) {
    return tabs.map((tab) {
      final isActive = activeTab == tab;
      final isPostJob = tab == AppView.postJob;

      if (isPostJob) {
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChange(tab),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal600.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    AppTranslations.t('postJob', lang),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final item = _navItem(tab, lang);
      return Expanded(
        child: GestureDetector(
          onTap: () => onTabChange(tab),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.teal50 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isActive ? item.activeColor : AppColors.slate400,
                    ),
                    if (tab == AppView.chat && totalUnread > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.rose500,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              totalUnread > 9 ? '9+' : '$totalUnread',
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? item.activeColor : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  _NavItem _navItem(AppView tab, LanguageOption lang) {
    switch (tab) {
      case AppView.home:
        return _NavItem(Icons.home_outlined,
            AppTranslations.t('home', lang), AppColors.teal600);
      case AppView.jobsNearMe:
        return _NavItem(Icons.list_alt,
            AppTranslations.t('jobsFeed', lang), AppColors.teal600);
      case AppView.postJob:
        return _NavItem(Icons.add_circle_outline,
            AppTranslations.t('postJob', lang), AppColors.teal600);
      case AppView.nearbyWorkersMap:
        return _NavItem(Icons.location_on_outlined,
            AppTranslations.t('map', lang), AppColors.teal600);
      case AppView.chat:
        return _NavItem(Icons.chat_outlined,
            AppTranslations.t('chat', lang), AppColors.teal600);
      case AppView.history:
        return _NavItem(Icons.attach_money,
            AppTranslations.t('earnings', lang), AppColors.teal600);
      case AppView.profile:
        return _NavItem(Icons.person_outline,
            AppTranslations.t('profile', lang), AppColors.teal600);
      default:
        return _NavItem(Icons.home_outlined,
            AppTranslations.t('home', lang), AppColors.teal600);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  const _NavItem(this.icon, this.label, this.activeColor);
}
