import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/notification_item.dart';

void main() {
  group('NotificationItem', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final notif = NotificationItem(
        id: 'notif-1',
        profileId: 'profile-emp-1',
        type: NotificationType.workerInterested,
        titleEn: 'Worker Interested',
        titleUr: 'کاریگر نے دلچسپی ظاہر کی',
        bodyEn: 'A worker is interested in your job.',
        bodyUr: 'کاریگر نے آپ کے کام میں دلچسپی ظاہر کی ہے۔',
        payload: {'jobId': 'job-101'},
        isRead: false,
        createdAt: now,
      );

      final json = notif.toJson();
      final restored = NotificationItem.fromJson(json);

      expect(restored.id, 'notif-1');
      expect(restored.type, NotificationType.workerInterested);
      expect(restored.payload?['jobId'], 'job-101');
      expect(restored.isRead, false);
    });

    test('copyWith updates isRead', () {
      final now = DateTime.now();
      final notif = NotificationItem(
        id: 'notif-2',
        profileId: 'profile-1',
        type: NotificationType.newJobRadius,
        createdAt: now,
      );

      final read = notif.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, 'notif-2');
    });

    test('parses all notification types from snake_case', () {
      final now = DateTime.now();
      final base = {
        'id': 'notif-test',
        'profile_id': 'p1',
        'title_en': 'Test',
        'title_ur': 'ٹیسٹ',
        'body_en': 'Test body',
        'body_ur': 'ٹیسٹ باڈی',
        'created_at': now.toIso8601String(),
      };

      expect(
        NotificationItem.fromJson({...base, 'type': 'new_job_radius'}).type,
        NotificationType.newJobRadius,
      );
      expect(
        NotificationItem.fromJson({...base, 'type': 'worker_interested'}).type,
        NotificationType.workerInterested,
      );
      expect(
        NotificationItem.fromJson({...base, 'type': 'job_hired'}).type,
        NotificationType.jobHired,
      );
      expect(
        NotificationItem.fromJson({...base, 'type': 'new_message'}).type,
        NotificationType.newMessage,
      );
      expect(
        NotificationItem.fromJson({...base, 'type': 'review_received'}).type,
        NotificationType.reviewReceived,
      );
    });
  });
}
