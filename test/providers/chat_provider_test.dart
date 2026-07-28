import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/chat_provider.dart';
import 'package:rozgar/models/conversation.dart';

void main() {
  late ChatNotifier notifier;

  Conversation makeConv({String id = 'conv-1'}) => Conversation(
        id: id,
        jobId: 'job-1',
        employerProfileId: 'emp-1',
        workerProfileId: 'wrk-1',
        lastMessageText: 'Hello',
        lastMessageTime: DateTime.now(),
      );

  setUp(() {
    notifier = ChatNotifier();
  });

  group('ChatNotifier initial state', () {
    test('conversations is empty', () {
      expect(notifier.conversations, isEmpty);
    });

    test('messages is empty', () {
      expect(notifier.messages, isEmpty);
    });

    test('lastOperationError is null', () {
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('ChatNotifier setConversations', () {
    test('replaces conversation list', () {
      notifier.setConversations([makeConv(), makeConv(id: 'conv-2')]);
      expect(notifier.conversations.length, 2);
    });
  });

  group('ChatNotifier setMessages', () {
    test('replaces message list', () {
      final msgs = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderProfileId: 'emp-1',
          contentType: ContentType.text,
          content: 'Hello',
          sentAt: DateTime.now(),
        ),
      ];
      notifier.setMessages(msgs);
      expect(notifier.messages.length, 1);
    });
  });

  group('ChatNotifier getOrCreateConversation', () {
    test('returns existing conversation if found', () {
      notifier.setConversations([makeConv()]);
      final result = notifier.getOrCreateConversation('job-1', 'wrk-1', 'emp-1');
      expect(result.id, 'conv-1');
      expect(notifier.conversations.length, 1);
    });

    test('creates new conversation if not found', () {
      notifier.setConversations([makeConv()]);
      final result = notifier.getOrCreateConversation('job-2', 'wrk-2', 'emp-1');
      expect(result.jobId, 'job-2');
      expect(result.workerProfileId, 'wrk-2');
      expect(notifier.conversations.length, 2);
    });
  });

  group('ChatNotifier sendMessage', () {
    test('adds message and updates conversation lastMessage', () {
      notifier.setConversations([makeConv()]);
      notifier.sendMessage(
        'conv-1',
        'Hi there!',
        senderProfileId: 'emp-1',
      );
      expect(notifier.messages.length, 1);
      expect(notifier.messages[0].content, 'Hi there!');
      expect(notifier.conversations[0].lastMessageText, 'Hi there!');
    });

    test('sanitizes message content', () {
      notifier.setConversations([makeConv()]);
      notifier.sendMessage(
        'conv-1',
        '<script>alert("xss")</script>Hello',
        senderProfileId: 'emp-1',
      );
      expect(notifier.messages[0].content, isNot(contains('<script>')));
    });
  });

  group('ChatNotifier clear', () {
    test('resets all state', () {
      notifier.setConversations([makeConv()]);
      notifier.setMessages([
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderProfileId: 'emp-1',
          contentType: ContentType.text,
          content: 'Hello',
          sentAt: DateTime.now(),
        ),
      ]);
      notifier.clear();
      expect(notifier.conversations, isEmpty);
      expect(notifier.messages, isEmpty);
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('ChatNotifier clearOperationError', () {
    test('resets error to null', () {
      notifier.clearOperationError();
      expect(notifier.lastOperationError, isNull);
    });
  });
}
