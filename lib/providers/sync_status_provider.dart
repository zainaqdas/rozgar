import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

/// Notifier that exposes SyncService dead-letter state to the UI layer.
/// Polls dead-letter operations and supports retry/dismiss actions.
class SyncStatusNotifier extends ChangeNotifier {
  final SyncService _syncService;
  List<QueuedOperation> _deadLetterOps = [];
  bool _isRetrying = false;

  SyncStatusNotifier({SyncService? syncService})
      : _syncService = syncService ?? SyncService.instance;

  List<QueuedOperation> get deadLetterOps => _deadLetterOps;
  bool get hasFailures => _deadLetterOps.isNotEmpty;
  bool get isRetrying => _isRetrying;
  int get failureCount => _deadLetterOps.length;

  /// Refresh the dead-letter list from SyncService.
  void refresh() {
    _deadLetterOps = _syncService.getDeadLetterOperations();
    notifyListeners();
  }

  /// Retry a single dead-lettered operation by ID.
  Future<void> retry(String id) async {
    _isRetrying = true;
    notifyListeners();
    try {
      await _syncService.retryDeadLetter(id);
      _deadLetterOps = _syncService.getDeadLetterOperations();
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  /// Retry all dead-lettered operations.
  Future<void> retryAll() async {
    _isRetrying = true;
    notifyListeners();
    try {
      final ids = _deadLetterOps.map((op) => op.id).toList();
      for (final id in ids) {
        await _syncService.retryDeadLetter(id);
      }
      _deadLetterOps = _syncService.getDeadLetterOperations();
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  /// Dismiss a single dead-lettered operation (permanently removes it).
  Future<void> dismiss(String id) async {
    await _syncService.removeDeadLetter(id);
    _deadLetterOps = _deadLetterOps.where((op) => op.id != id).toList();
    notifyListeners();
  }

  /// Dismiss all dead-lettered operations.
  Future<void> dismissAll() async {
    await _syncService.clearDeadLetter();
    _deadLetterOps = [];
    notifyListeners();
  }
}
