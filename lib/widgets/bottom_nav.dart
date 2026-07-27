import 'package:flutter/material.dart';
import '../app.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import '../models/profile.dart';

class RozgarBottomNav extends StatelessWidget {
  final AppState appState;
  final AppView activeTab;
  final List<AppView> tabs;
  final ValueChanged<AppView> onTabChange;

  const RozgarBottomNav({
    super.key,
    required this.appState,
    required this.activeTab,
    required this.tabs,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    final totalUnread = appState.conversations.fold<int>(
      0,
      (acc, c) =>
          acc +
          (appState.activeProfileType == ProfileType.employer
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
        // Special Post Job CTA button
        return GestureDetector(
          onTap: () => onTabChange(tab),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.teal600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal600.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.add_circle_outline,
                        size: 24, color: Colors.white),
                  ),
                ),
              ),
              const Text(
                'Post Job',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal700,
                ),
              ),
            ],
          ),
        );
      }

      final item = _navItem(tab, lang);
      return Tooltip(
        message: item.label,
        child: GestureDetector(
        onTap: () => onTabChange(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
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
                    color: isActive
                        ? item.activeColor
                        : AppColors.slate500,
                  ),
                  if (tab == AppView.chat && totalUnread > 0)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.teal600
                              : AppColors.slate400,
                          shape: BoxShape.circle,
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
                  color: isActive
                      ? item.activeColor
                      : AppColors.slate500,
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
