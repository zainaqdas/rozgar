import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/conversation.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  group('Conversation', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'conv-101',
        jobId: 'job-101',
        employerProfileId: 'profile-emp-1',
        workerProfileId: 'profile-wrk-1',
        lastMessageText: 'Hello!',
        lastMessageTime: now,
        unreadCountEmployer: 1,
        unreadCountWorker: 0,
      );

      final json = conv.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, 'conv-101');
      expect(restored.lastMessageText, 'Hello!');
      expect(restored.unreadCountEmployer, 1);
      expect(restored.unreadCountWorker, 0);
    });

    test('copyWith updates last message', () {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'conv-1',
        jobId: 'job-1',
        employerProfileId: 'emp-1',
        workerProfileId: 'wrk-1',
      );

      final updated = conv.copyWith(
        lastMessageText: 'Updated',
        lastMessageTime: now,
        unreadCountEmployer: 2,
      );
      expect(updated.lastMessageText, 'Updated');
      expect(updated.unreadCountEmployer, 2);
      expect(updated.id, 'conv-1');
    });
  });

  group('Message', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg-101',
        conversationId: 'conv-101',
        senderProfileId: 'profile-emp-1',
        contentType: ContentType.text,
        content: 'Assalam-o-Alaikum!',
        sentAt: now,
        mediaUrl: null,
        audioDurationSec: null,
        locationPoint: null,
      );

      final json = msg.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, 'msg-101');
      expect(restored.content, 'Assalam-o-Alaikum!');
      expect(restored.contentType, ContentType.text);
    });

    test('parses all content types', () {
      final now = DateTime.now();
      final base = {
        'id': 'msg-test',
        'conversation_id': 'conv-1',
        'sender_profile_id': 'usr-1',
        'content': 'test',
        'sent_at': now.toIso8601String(),
      };

      expect(Message.fromJson({...base, 'content_type': 'image'}).contentType, ContentType.image);
      expect(Message.fromJson({...base, 'content_type': 'voice'}).contentType, ContentType.voice);
      expect(Message.fromJson({...base, 'content_type': 'location'}).contentType, ContentType.location);
      expect(Message.fromJson({...base, 'content_type': 'quote'}).contentType, ContentType.quote);
    });

    test('supports location point on message', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg-102',
        conversationId: 'conv-1',
        senderProfileId: 'usr-1',
        contentType: ContentType.location,
        content: '📍 Live Location',
        sentAt: now,
        locationPoint: const LocationPoint(lat: 31.5204, lng: 74.3587, address: 'Gulberg'),
      );

      final json = msg.toJson();
      final restored = Message.fromJson(json);
      expect(restored.locationPoint?.lat, 31.5204);
      expect(restored.locationPoint?.address, 'Gulberg');
    });

    test('fromJson handles malformed sent_at gracefully', () {
      final json = {
        'id': 'msg-bad-date',
        'conversation_id': 'conv-1',
        'sender_profile_id': 'p-1',
        'content_type': 'text',
        'content': 'hello',
        'sent_at': 'not-a-date',
        'read_at': null,
        'media_url': null,
        'audio_duration_sec': null,
        'location_point': null,
      };
      final msg = Message.fromJson(json);
      expect(msg.id, 'msg-bad-date');
      expect(msg.sentAt, isA<DateTime>());
    });

    test('fromJson handles null sent_at gracefully', () {
      final json = {
        'id': 'msg-null-date',
        'conversation_id': 'conv-1',
        'sender_profile_id': 'p-1',
        'content_type': 'text',
        'content': 'hello',
        'sent_at': null,
        'read_at': null,
        'media_url': null,
        'audio_duration_sec': null,
        'location_point': null,
      };
      final msg = Message.fromJson(json);
      expect(msg.sentAt, isA<DateTime>());
      expect(msg.readAt, isNull);
    });

    test('fromJson handles malformed read_at gracefully', () {
      final json = {
        'id': 'msg-bad-read',
        'conversation_id': 'conv-1',
        'sender_profile_id': 'p-1',
        'content_type': 'text',
        'content': 'hello',
        'sent_at': '2025-01-01T00:00:00.000Z',
        'read_at': 'garbage',
        'media_url': null,
        'audio_duration_sec': null,
        'location_point': null,
      };
      final msg = Message.fromJson(json);
      expect(msg.readAt, isNull);
    });

    test('fromJson handles audio_duration_sec as double', () {
      final json = {
        'id': 'msg-dbl',
        'conversation_id': 'conv-1',
        'sender_profile_id': 'p-1',
        'content_type': 'voice',
        'content': '',
        'sent_at': '2025-01-01T00:00:00.000Z',
        'read_at': null,
        'media_url': null,
        'audio_duration_sec': 12.0,
        'location_point': null,
      };
      final msg = Message.fromJson(json);
      expect(msg.audioDurationSec, 12);
    });
  });
}
