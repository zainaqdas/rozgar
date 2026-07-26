import 'location_point.dart';

enum ContentType { text, image, voice, location, quote }

class Conversation {
  final String id;
  final String jobId;
  final String employerProfileId;
  final String workerProfileId;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final int unreadCountEmployer;
  final int unreadCountWorker;

  const Conversation({
    required this.id,
    required this.jobId,
    required this.employerProfileId,
    required this.workerProfileId,
    this.lastMessageText,
    this.lastMessageTime,
    this.unreadCountEmployer = 0,
    this.unreadCountWorker = 0,
  });

  Conversation copyWith({
    String? lastMessageText,
    DateTime? lastMessageTime,
    int? unreadCountEmployer,
    int? unreadCountWorker,
  }) =>
      Conversation(
        id: id,
        jobId: jobId,
        employerProfileId: employerProfileId,
        workerProfileId: workerProfileId,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCountEmployer:
            unreadCountEmployer ?? this.unreadCountEmployer,
        unreadCountWorker: unreadCountWorker ?? this.unreadCountWorker,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'employer_profile_id': employerProfileId,
        'worker_profile_id': workerProfileId,
        'last_message_text': lastMessageText,
        'last_message_time': lastMessageTime?.toIso8601String(),
        'unread_count_employer': unreadCountEmployer,
        'unread_count_worker': unreadCountWorker,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        employerProfileId: json['employer_profile_id'] as String,
        workerProfileId: json['worker_profile_id'] as String,
        lastMessageText: json['last_message_text'] as String?,
        lastMessageTime: json['last_message_time'] != null
            ? DateTime.parse(json['last_message_time'] as String)
            : null,
        unreadCountEmployer:
            (json['unread_count_employer'] as num?)?.toInt() ?? 0,
        unreadCountWorker:
            (json['unread_count_worker'] as num?)?.toInt() ?? 0,
      );
}

class Message {
  final String id;
  final String conversationId;
  final String senderProfileId;
  final ContentType contentType;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? mediaUrl;
  final int? audioDurationSec;
  final LocationPoint? locationPoint;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    this.contentType = ContentType.text,
    this.content = '',
    required this.sentAt,
    this.readAt,
    this.mediaUrl,
    this.audioDurationSec,
    this.locationPoint,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_profile_id': senderProfileId,
        'content_type': contentType.name,
        'content': content,
        'sent_at': sentAt.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'media_url': mediaUrl,
        'audio_duration_sec': audioDurationSec,
        'location_point': locationPoint?.toJson(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderProfileId: json['sender_profile_id'] as String,
        contentType: _parseContentType(json['content_type']),
        content: json['content'] as String? ?? '',
        sentAt: DateTime.parse(json['sent_at'] as String),
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        mediaUrl: json['media_url'] as String?,
        audioDurationSec: json['audio_duration_sec'] as int?,
        locationPoint: json['location_point'] != null
            ? LocationPoint.fromJson(
                json['location_point'] as Map<String, dynamic>)
            : null,
      );

  static ContentType _parseContentType(dynamic v) {
    switch (v) {
      case 'image':
        return ContentType.image;
      case 'voice':
        return ContentType.voice;
      case 'location':
        return ContentType.location;
      case 'quote':
        return ContentType.quote;
      default:
        return ContentType.text;
    }
  }
}
