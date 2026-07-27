import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/conversation.dart';
import '../models/job.dart';
import '../models/application.dart';
import 'supabase_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class QueuedOperation {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const QueuedOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
      };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) =>
      QueuedOperation(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _boxName = 'offline_queue';
  Box<String>? _box;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    _listenConnectivity();
    final count = _box!.length;
    if (count > 0) {
      debugPrint('SyncService: $count pending operations in queue');
    }
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncAll();
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
    await _box?.put(op.id, jsonEncode(op.toJson()));
    debugPrint('SyncService: enqueued $type');
  }

  Future<int> get pendingCount async => _box?.length ?? 0;

  Future<void> syncAll() async {
    if (_isSyncing || _box == null || _box!.isEmpty) return;
    _isSyncing = true;
    debugPrint('SyncService: starting sync of ${_box!.length} items');

    final ids = _box!.keys.toList();
    for (final id in ids) {
      final raw = _box!.get(id);
      if (raw == null) continue;
      try {
        final op = QueuedOperation.fromJson(jsonDecode(raw));
        await _processOperation(op);
        await _box!.delete(id);
        debugPrint('SyncService: synced $id (${op.type})');
      } catch (e) {
        debugPrint('SyncService: failed to sync $id: $e');
      }
    }
    _isSyncing = false;
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
              (c) => c.name == (op.payload['content_type'] as String? ?? 'text'),
            ),
            content: op.payload['content'] as String? ?? '',
            mediaUrl: op.payload['media_url'] as String?,
            sentAt: DateTime.tryParse(
                    op.payload['sent_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      case 'create_job':
        await supabase.createJob(Job.fromJson(op.payload));
      case 'express_interest':
        await supabase.createApplication(
            Application.fromJson(op.payload));
    }
  }

  Future<void> clear() async {
    await _box?.clear();
    debugPrint('SyncService: queue cleared');
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _box?.close();
  }
}
