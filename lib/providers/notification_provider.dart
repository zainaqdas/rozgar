import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

class NotificationNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<NotificationItem> _notifications = [];
  RealtimeChannel? _notificationChannel;
  String? _lastOperationError;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  void setNotifications(List<NotificationItem> notifications) {
    _notifications = notifications;
    notifyListeners();
  }

  void subscribe(String profileId) {
    _notificationChannel?.unsubscribe();
    _notificationChannel = _supabase.subscribeToNotifications(profileId, (
      notification,
    ) {
      _notifications = [notification, ..._notifications];
      notifyListeners();
    });
  }

  void markNotificationsRead(String? profileId) {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
    if (profileId != null) {
      _fireAndForget(
        'mark_notifications_read',
        {'profile_id': profileId},
        () => _supabase.markNotificationsRead(profileId),
      );
    }
  }

  void _fireAndForget(
    String type,
    Map<String, dynamic> payload,
    Future<dynamic> Function() task,
  ) {
    task().then(
      (_) {},
      onError: (e) {
        debugPrint('$type failed: $e');
        _lastOperationError ??= '$type failed';
        notifyListeners();
        // Enqueue operation for retry
        final syncService = SyncService.instance;
        syncService.enqueue(type, payload);
      },
    );
  }

  void unsubscribe() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  void clear() {
    unsubscribe();
    _notifications = [];
    _lastOperationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
