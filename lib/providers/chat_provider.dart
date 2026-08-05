import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/notification_item.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
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

    _fireAndForget(
      'send_message',
      msg.toJson(),
      () => _supabase.sendMessage(msg),
    );
    _fireAndForget(
      'update_conversation_last_message',
      {
        'conversation_id': conversationId,
        'last_message_text': safeContent,
        'last_message_time': DateTime.now().toIso8601String(),
      },
      () => _supabase.updateConversationLastMessage(
        conversationId,
        lastMessageText: safeContent,
        lastMessageTime: DateTime.now(),
      ),
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
    _fireAndForget(
      'create_notification',
      notif.toJson(),
      () => _supabase.createNotification(notif),
    );
  }

  Conversation getOrCreateConversation(
    String jobId,
    String workerProfileId,
    String employerProfileId,
  ) {
    final existing = _conversations
        .where((c) => c.jobId == jobId && c.workerProfileId == workerProfileId)
        .firstOrNull;
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

    getOrCreateConversationInSupabase(
      jobId,
      workerProfileId,
      employerProfileId,
    );
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
    // Route realtime inserts through handleRealtimeMessage so the
    // sender's own realtime echo is deduplicated by message ID.
    final channel = _supabase.subscribeToMessages(
      conversationId,
      handleRealtimeMessage,
    );
    _messageChannels.add(channel);
  }

  void subscribeToAll() {
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    for (final conv in _conversations) {
      subscribeToConversation(conv.id);
    }
  }

  void handleRealtimeMessage(Message message) {
    if (_messages.any((m) => m.id == message.id)) return;
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
