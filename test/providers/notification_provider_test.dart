import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/notification_provider.dart';
import 'package:rozgar/models/notification_item.dart';

void main() {
  late NotificationNotifier notifier;

  setUp(() {
    notifier = NotificationNotifier();
  });

  group('NotificationNotifier initial state', () {
    test('notifications is empty', () {
      expect(notifier.notifications, isEmpty);
    });

    test('lastOperationError is null', () {
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('NotificationNotifier setNotifications', () {
    test('replaces notification list', () {
      final notifs = [
        NotificationItem(
          id: 'n-1',
          profileId: 'p-1',
          type: NotificationType.newJobRadius,
          titleEn: 'New Job',
          bodyEn: 'A new job was posted nearby',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      notifier.setNotifications(notifs);
      expect(notifier.notifications.length, 1);
      expect(notifier.notifications[0].titleEn, 'New Job');
    });
  });

  group('NotificationNotifier markNotificationsRead', () {
    test('marks all notifications as read', () {
      final notifs = [
        NotificationItem(
          id: 'n-1',
          profileId: 'p-1',
          type: NotificationType.newJobRadius,
          titleEn: 'New Job',
          bodyEn: 'A new job was posted',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationItem(
          id: 'n-2',
          profileId: 'p-1',
          type: NotificationType.workerInterested,
          titleEn: 'Application',
          bodyEn: 'New application received',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      notifier.setNotifications(notifs);
      notifier.markNotificationsRead(null);
      expect(notifier.notifications.every((n) => n.isRead), isTrue);
    });
  });

  group('NotificationNotifier clear', () {
    test('clears notifications and error', () {
      final notifs = [
        NotificationItem(
          id: 'n-1',
          profileId: 'p-1',
          type: NotificationType.jobHired,
          titleEn: 'Hired',
          bodyEn: 'You have been hired',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      notifier.setNotifications(notifs);
      notifier.clear();
      expect(notifier.notifications, isEmpty);
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('NotificationNotifier clearOperationError', () {
    test('resets error to null', () {
      notifier.clearOperationError();
      expect(notifier.lastOperationError, isNull);
    });
  });
}
