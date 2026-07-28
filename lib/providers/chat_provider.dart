import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/notification_item.dart';
import '../services/supabase_service.dart';
import '../utils/sanitize.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ChatNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  String? _lastOperationError;

  final List<RealtimeChannel> _messageChannels = [];
  final Set<String> _subscribedConversationIds = {};

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<Message> get messages => List.unmodifiable(_messages);
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  void setConversations(List<Conversation> conversations) {
    _conversations = conversations;
    notifyListeners();
  }

  void setMessages(List<Message> messages) {
    _messages = messages;
    notifyListeners();
  }

  void sendMessage(
    String conversationId,
    String content, {
    required String senderProfileId,
    ContentType contentType = ContentType.text,
    String? mediaUrl,
  }) {
    final safeContent = sanitizeInput(content);
    final msg = Message(
      id: 'msg-${_uuid.v4()}',
      conversationId: conversationId,
      senderProfileId: senderProfileId,
      contentType: contentType,
      content: safeContent,
      mediaUrl: mediaUrl,
      sentAt: DateTime.now(),
    );
    _messages.add(msg);
    _conversations = _conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(
          lastMessageText: safeContent,
          lastMessageTime: msg.sentAt,
        );
      }
      return c;
    }).toList();
    notifyListeners();

    _fireAndForget('sendMessage', () async {
      await _supabase.sendMessage(msg);
      await _supabase.updateConversationLastMessage(
        conversationId,
        lastMessageText: safeContent,
        lastMessageTime: msg.sentAt,
      );

      // Notify the other conversation participant
      final conv = _conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );
      final recipientProfileId = conv.employerProfileId == senderProfileId
          ? conv.workerProfileId
          : conv.employerProfileId;

      final notif = NotificationItem(
        id: 'notif-${_uuid.v4()}',
        profileId: recipientProfileId,
        type: NotificationType.newMessage,
        titleEn: 'New Message',
        titleUr: 'نیا پیغام',
        bodyEn: safeContent.length > 50
            ? '${safeContent.substring(0, 50)}...'
            : safeContent,
        bodyUr: safeContent.length > 50
            ? '${safeContent.substring(0, 50)}...'
            : safeContent,
        isRead: false,
        createdAt: DateTime.now(),
        payload: {'conversationId': conversationId},
      );
      await _supabase.createNotification(notif);
    });
  }

  Conversation getOrCreateConversation(
    String jobId,
    String workerProfileId,
    String employerProfileId,
  ) {
    final existing = _conversations.where((c) =>
        c.jobId == jobId && c.workerProfileId == workerProfileId).firstOrNull;
    if (existing != null) return existing;

    final conv = Conversation(
      id: 'conv-${_uuid.v4()}',
      jobId: jobId,
      employerProfileId: employerProfileId,
      workerProfileId: workerProfileId,
      lastMessageText: 'Conversation started',
      lastMessageTime: DateTime.now(),
    );
    _conversations.insert(0, conv);
    notifyListeners();

    getOrCreateConversationInSupabase(jobId, workerProfileId, employerProfileId);
    return conv;
  }

  Future<void> getOrCreateConversationInSupabase(
    String jobId,
    String workerProfileId,
    String employerProfileId,
  ) async {
    try {
      final conv = await _supabase.getOrCreateConversation(
        jobId: jobId,
        employerProfileId: employerProfileId,
        workerProfileId: workerProfileId,
      );
      final existing = _conversations.indexWhere((c) => c.id == conv.id);
      if (existing == -1) {
        _conversations.insert(0, conv);
        subscribeToConversation(conv.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to create conversation: $e');
      _lastOperationError = 'Failed to create conversation';
      notifyListeners();
    }
  }

  void subscribeToConversation(String conversationId) {
    if (!_subscribedConversationIds.add(conversationId)) return;
    final channel = _supabase.subscribeToMessages(
      conversationId,
      (message) {
        _messages = [..._messages, message];
        _conversations = _conversations.map((c) {
          if (c.id == message.conversationId) {
            return c.copyWith(
              lastMessageText: message.content,
              lastMessageTime: message.sentAt,
            );
          }
          return c;
        }).toList();
        notifyListeners();
      },
    );
    _messageChannels.add(channel);
  }

  void subscribeToAllConversations(List<Conversation> conversations) {
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    _subscribedConversationIds.clear();
    for (final conv in conversations) {
      subscribeToConversation(conv.id);
    }
  }

  void handleRealtimeMessage(Message message) {
    _messages = [..._messages, message];
    _conversations = _conversations.map((c) {
      if (c.id == message.conversationId) {
        return c.copyWith(
          lastMessageText: message.content,
          lastMessageTime: message.sentAt,
        );
      }
      return c;
    }).toList();
    notifyListeners();
  }

  void _fireAndForget(String label, Future<dynamic> Function() task) {
    task().then((_) {}, onError: (e) {
      debugPrint('$label failed: $e');
      _lastOperationError = '$label failed';
      notifyListeners();
    });
  }

  void unsubscribeAll() {
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    _subscribedConversationIds.clear();
  }

  void clear() {
    unsubscribeAll();
    _conversations = [];
    _messages = [];
    _lastOperationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}
