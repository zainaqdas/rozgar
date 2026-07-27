import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class NotificationsView extends StatelessWidget {
  final AppState appState;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenJobDetailsById;

  const NotificationsView({
    super.key,
    required this.appState,
    required this.onBack,
    required this.onOpenJobDetailsById,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.language;
    final notifications = appState.notifications;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.slate200)),
              ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppTranslations.t('notifications', lang),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                        const Text('Live FCM job alerts & match updates',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  ScalePress(
                    onTap: appState.markNotificationsRead,
                    child: Text(AppTranslations.t('markAllRead', lang),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal700)),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: notifications.isEmpty
                  ? const FadeInSlide(
                      index: 0,
                      child: EmptyState(
                        icon: Icons.notifications_none,
                        title: 'All Caught Up!',
                        message: 'No new notifications right now. Check back when new jobs or updates arrive.',
                        iconColor: AppColors.teal600,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return FadeInSlide(
                          index: i,
                          delayPerItem: const Duration(milliseconds: 60),
                          child: GestureDetector(
                            onTap: () {
                              if (n.payload?['jobId'] != null) {
                                onOpenJobDetailsById(n.payload!['jobId'].toString());
                              }
                            },
                            child: Container(
                              width: double.maxFinite,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.isRead ? Colors.white : AppColors.teal50.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: n.isRead ? AppColors.slate200 : AppColors.teal200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal600),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          lang == LanguageOption.ur ? n.titleUr : n.titleEn,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate800),
                                        ),
                                      ),
                                      Text(timeAgo(n.createdAt),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.slate400)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lang == LanguageOption.ur ? n.bodyUr : n.bodyEn,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate600, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
