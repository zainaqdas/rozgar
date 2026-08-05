import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/conversation.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/notification_item.dart';
import '../models/review.dart';
import 'supabase_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Maximum sync attempts before an operation is moved to dead-letter.
const int maxSyncAttempts = 3;

class QueuedOperation {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  const QueuedOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  QueuedOperation copyWith({int? attempts}) => QueuedOperation(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
    'attempts': attempts,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) =>
      QueuedOperation(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _boxName = 'offline_queue';
  static const _deadLetterBoxName = 'offline_dead_letter';
  Box<String>? _box;
  Box<String>? _deadLetterBox;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Operations enqueued before [initialize] completed, held in memory
  /// and flushed to the Hive box once it is open.
  final List<QueuedOperation> _pendingBeforeInit = [];

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    _deadLetterBox = await Hive.openBox<String>(_deadLetterBoxName);
    _listenConnectivity();
    // Flush operations that were buffered before initialization.
    for (final op in _pendingBeforeInit) {
      await _box!.put(op.id, jsonEncode(op.toJson()));
    }
    if (_pendingBeforeInit.isNotEmpty) {
      debugPrint(
        'SyncService: flushed ${_pendingBeforeInit.length} buffered operations',
      );
      _pendingBeforeInit.clear();
    }
    final count = _box!.length;
    if (count > 0) {
      debugPrint('SyncService: $count queued operations pending');
      _processQueue();
    }
    final deadCount = _deadLetterBox!.length;
    if (deadCount > 0) {
      debugPrint('SyncService: $deadCount operations in dead-letter');
    }
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && _box!.isNotEmpty) {
        debugPrint('SyncService: connectivity restored, syncing...');
        _processQueue();
      }
    });
  }

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final op = QueuedOperation(
      id: 'op-${_uuid.v4()}',
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    final box = _box;
    if (box == null) {
      // Not initialized yet (early in app startup, or in unit tests) —
      // buffer in memory instead of crashing; initialize() flushes these.
      _pendingBeforeInit.add(op);
      debugPrint('SyncService: buffered ${op.id} ($type) until initialized');
      return;
    }
    await box.put(op.id, jsonEncode(op.toJson()));
    debugPrint('SyncService: enqueued ${op.id} ($type)');
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final keys = _box!.keys.toList();
    for (final id in keys) {
      final raw = _box!.get(id);
      if (raw == null) continue;

      try {
        final op = QueuedOperation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        await _processOperation(op);
        await _box!.delete(id);
        debugPrint('SyncService: synced $id (${op.type})');
      } catch (e) {
        debugPrint('SyncService: failed to sync $id: $e');
        await _handleFailure(id, raw);
      }
    }
    _isSyncing = false;
  }

  /// Increment attempt counter; move to dead-letter after [maxSyncAttempts].
  Future<void> _handleFailure(String id, String raw) async {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final attempts = (json['attempts'] as num?)?.toInt() ?? 0;
      final newAttempts = attempts + 1;

      if (newAttempts >= maxSyncAttempts) {
        json['attempts'] = newAttempts;
        json['dead_lettered_at'] = DateTime.now().toIso8601String();
        await _deadLetterBox!.put(id, jsonEncode(json));
        await _box!.delete(id);
        debugPrint(
          'SyncService: $id moved to dead-letter after $newAttempts attempts',
        );
      } else {
        json['attempts'] = newAttempts;
        await _box!.put(id, jsonEncode(json));
        debugPrint('SyncService: $id attempt $newAttempts/$maxSyncAttempts');
      }
    } catch (e) {
      debugPrint('SyncService: failed to handle failure for $id: $e');
    }
  }

  /// Returns all dead-lettered operations for inspection or manual retry.
  List<QueuedOperation> getDeadLetterOperations() {
    if (_deadLetterBox == null) return [];
    return _deadLetterBox!.values.map((raw) {
      return QueuedOperation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }).toList();
  }

  /// Re-queues a dead-lettered operation for another sync round.
  Future<void> retryDeadLetter(String id) async {
    final deadLetterBox = _deadLetterBox;
    final box = _box;
    if (deadLetterBox == null || box == null) return;
    final raw = deadLetterBox.get(id);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    json['attempts'] = 0;
    json.remove('dead_lettered_at');
    await box.put(id, jsonEncode(json));
    await deadLetterBox.delete(id);
    debugPrint('SyncService: re-queued dead-letter $id');
    _processQueue();
  }

  /// Removes a single dead-lettered operation permanently.
  Future<void> removeDeadLetter(String id) async {
    await _deadLetterBox?.delete(id);
    debugPrint('SyncService: removed dead-letter $id');
  }

  /// Clears all dead-lettered operations permanently.
  Future<void> clearDeadLetter() async {
    await _deadLetterBox?.clear();
    debugPrint('SyncService: dead-letter cleared');
  }

  Future<void> _processOperation(QueuedOperation op) async {
    final supabase = SupabaseService.instance;
    switch (op.type) {
      case 'send_message':
        await supabase.sendMessage(
          Message(
            id: op.payload['id'] as String? ?? '',
            conversationId: op.payload['conversation_id'] as String? ?? '',
            senderProfileId: op.payload['sender_profile_id'] as String? ?? '',
            contentType: ContentType.values.firstWhere(
              (c) =>
                  c.name == (op.payload['content_type'] as String? ?? 'text'),
            ),
            content: op.payload['content'] as String? ?? '',
            mediaUrl: op.payload['media_url'] as String?,
            sentAt:
                DateTime.tryParse(op.payload['sent_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      case 'create_job':
        await supabase.createJob(Job.fromJson(op.payload));
      case 'express_interest':
        await supabase.createApplication(Application.fromJson(op.payload));
      case 'update_job_status':
        await supabase.updateJobStatus(
          op.payload['job_id'] as String,
          status: op.payload['status'] as String,
          hiredWorkerProfileId:
              op.payload['hired_worker_profile_id'] as String?,
        );
      case 'hire_and_reject':
        await supabase.hireAndReject(
          jobId: op.payload['job_id'] as String,
          hiredWorkerProfileId: op.payload['hired_worker_profile_id'] as String,
          rejectApplicationIds: (op.payload['reject_application_ids'] as List)
              .cast<String>(),
        );
      case 'create_notification':
        await supabase.createNotification(
          NotificationItem.fromJson(op.payload),
        );
      case 'update_conversation_last_message':
        await supabase.updateConversationLastMessage(
          op.payload['conversation_id'] as String,
          lastMessageText: op.payload['last_message_text'] as String,
          lastMessageTime: DateTime.parse(
            op.payload['last_message_time'] as String,
          ),
        );
      case 'mark_notifications_read':
        await supabase.markNotificationsRead(
          op.payload['profile_id'] as String,
        );
      case 'update_worker_details':
        await supabase.updateWorkerDetails(
          op.payload['profile_id'] as String,
          op.payload['updates'] as Map<String, dynamic>,
        );
      case 'add_review':
        await supabase.createReview(Review.fromJson(op.payload));
      case 'profile_photo':
        await supabase.updateProfile(op.payload['profile_id'] as String, {
          'profile_photo_url': op.payload['photo_url'] as String,
        });
      default:
        throw StateError('Unknown sync operation type: ${op.type}');
    }
  }

  Future<void> clear() async {
    await _box?.clear();
    debugPrint('SyncService: queue cleared');
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _box?.close();
    await _deadLetterBox?.close();
  }
}
