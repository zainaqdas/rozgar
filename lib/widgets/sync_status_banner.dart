import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

/// A persistent banner shown above the bottom nav when sync operations
/// have failed and moved to the dead-letter queue. Offers retry/dismiss.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    if (!syncStatus.hasFailures) return const SizedBox.shrink();

    final count = syncStatus.failureCount;
    final isRetrying = syncStatus.isRetrying;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.rose50,
        border: Border(top: BorderSide(color: AppColors.rose200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.rose500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1
                    ? context.t('syncFailedOne')
                    : context.t('syncFailedMany').replaceAll('{0}', '$count'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ),
            if (isRetrying)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.rose500,
                ),
              )
            else ...[
              TextButton(
                onPressed: () =>
                    ref.read(syncStatusProvider.notifier).retryAll(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.t('retry'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rose500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () =>
                    ref.read(syncStatusProvider.notifier).dismissAll(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.t('dismiss'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
