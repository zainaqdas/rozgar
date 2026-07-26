enum NotificationType {
  newJobRadius,
  workerInterested,
  jobHired,
  newMessage,
  reviewReceived,
}

class NotificationItem {
  final String id;
  final String profileId;
  final NotificationType type;
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.profileId,
    required this.type,
    this.titleEn = '',
    this.titleUr = '',
    this.bodyEn = '',
    this.bodyUr = '',
    this.payload,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        profileId: profileId,
        type: type,
        titleEn: titleEn,
        titleUr: titleUr,
        bodyEn: bodyEn,
        bodyUr: bodyUr,
        payload: payload,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  /// Converts a camelCase enum name (e.g. "workerInterested") to
  /// snake_case (e.g. "worker_interested") for database storage.
  static String _enumNameToSnakeCase(String name) {
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'type': _enumNameToSnakeCase(type.name),
        'title_en': titleEn,
        'title_ur': titleUr,
        'body_en': bodyEn,
        'body_ur': bodyUr,
        'payload': payload,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        type: _parseType(json['type']),
        titleEn: json['title_en'] as String? ?? '',
        titleUr: json['title_ur'] as String? ?? '',
        bodyEn: json['body_en'] as String? ?? '',
        bodyUr: json['body_ur'] as String? ?? '',
        payload: json['payload'] as Map<String, dynamic>?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  static NotificationType _parseType(dynamic v) {
    switch (v) {
      case 'worker_interested':
        return NotificationType.workerInterested;
      case 'job_hired':
        return NotificationType.jobHired;
      case 'new_message':
        return NotificationType.newMessage;
      case 'review_received':
        return NotificationType.reviewReceived;
      default:
        return NotificationType.newJobRadius;
    }
  }
}
