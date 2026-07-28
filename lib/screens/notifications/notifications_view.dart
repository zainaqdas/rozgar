import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_states.dart';

class NotificationsView extends ConsumerWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onOpenJobDetailsById;

  const NotificationsView({
    super.key,
    required this.onBack,
    required this.onOpenJobDetailsById,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notificationNotifier = ref.watch(notificationProvider);
    final lang = settings.language;
    final notifications = notificationNotifier.notifications;

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
                  Text(
                    AppTranslations.t('notifications', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate800),
                  ),
                  const Spacer(),
                  if (notifications.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () {
                        final profileId = ref.read(profileProvider).activeProfileId;
                        ref.read(notificationProvider.notifier).markNotificationsRead(profileId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.teal50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.teal200),
                        ),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal700),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: notifications.isEmpty
                  ? EmptyState(
                  icon: Icons.notifications_none,
                  title: AppTranslations.t('nothingHereYet', lang),
                  message: AppTranslations.t('checkBackLater', lang),
                  )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return FadeInSlide(
                          index: index,
                          child: GestureDetector(
                            onTap: () {
                              final jobId = n.payload?['jobId'] as String?;
                              if (jobId != null) onOpenJobDetailsById(jobId);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: n.isRead ? Colors.white : AppColors.teal50,
                                borderRadius: BorderRadius.circular(12),
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
