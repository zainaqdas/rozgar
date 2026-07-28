import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/services/sync_service.dart';

void main() {
  group('QueuedOperation', () {
    test('serializes to JSON with attempts field', () {
      final op = QueuedOperation(
        id: 'op-1',
        type: 'send_message',
        payload: {'content': 'hello'},
        createdAt: DateTime(2026, 1, 15, 10, 30),
        attempts: 2,
      );

      final json = op.toJson();
      expect(json['id'], 'op-1');
      expect(json['type'], 'send_message');
      expect(json['payload'], {'content': 'hello'});
      expect(json['attempts'], 2);
      expect(json['created_at'], '2026-01-15T10:30:00.000');
    });

    test('deserializes from JSON with attempts', () {
      final json = {
        'id': 'op-2',
        'type': 'create_job',
        'payload': {'title': 'Fix pipe'},
        'created_at': '2026-03-20T14:00:00.000',
        'attempts': 1,
      };

      final op = QueuedOperation.fromJson(json);
      expect(op.id, 'op-2');
      expect(op.type, 'create_job');
      expect(op.payload['title'], 'Fix pipe');
      expect(op.attempts, 1);
      expect(op.createdAt, DateTime(2026, 3, 20, 14, 0));
    });

    test('defaults attempts to 0 when missing from JSON', () {
      final json = {
        'id': 'op-3',
        'type': 'express_interest',
        'payload': <String, dynamic>{},
        'created_at': '2026-05-01T08:00:00.000',
      };

      final op = QueuedOperation.fromJson(json);
      expect(op.attempts, 0);
    });

    test('round-trips through JSON encode/decode', () {
      final original = QueuedOperation(
        id: 'op-rt',
        type: 'send_message',
        payload: {'conversation_id': 'conv-1', 'content': 'test'},
        createdAt: DateTime(2026, 7, 28, 12, 0),
        attempts: 3,
      );

      final encoded = jsonEncode(original.toJson());
      final decoded = QueuedOperation.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>);

      expect(decoded.id, original.id);
      expect(decoded.type, original.type);
      expect(decoded.payload, original.payload);
      expect(decoded.attempts, original.attempts);
      expect(decoded.createdAt, original.createdAt);
    });

    test('copyWith updates attempts only', () {
      final op = QueuedOperation(
        id: 'op-cw',
        type: 'create_job',
        payload: {'budget': 5000},
        createdAt: DateTime(2026, 2, 1),
        attempts: 0,
      );

      final updated = op.copyWith(attempts: 2);
      expect(updated.attempts, 2);
      expect(updated.id, 'op-cw');
      expect(updated.type, 'create_job');
      expect(updated.payload['budget'], 5000);
    });

    test('handles malformed JSON gracefully', () {
      final op = QueuedOperation.fromJson({});
      expect(op.id, '');
      expect(op.type, '');
      expect(op.payload, isEmpty);
      expect(op.attempts, 0);
    });
  });

  group('maxSyncAttempts', () {
    test('is set to 3', () {
      expect(maxSyncAttempts, 3);
    });
  });
}
