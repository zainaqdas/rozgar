enum PreferredLanguage { en, ur }

class AuthIdentity {
  final String id;
  final String? phoneNumber;
  final String? email;
  final PreferredLanguage preferredLanguage;
  final DateTime createdAt;

  const AuthIdentity({
    required this.id,
    this.phoneNumber,
    this.email,
    this.preferredLanguage = PreferredLanguage.en,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'email': email,
        'preferred_language': preferredLanguage.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory AuthIdentity.fromJson(Map<String, dynamic> json) => AuthIdentity(
        id: json['id'] as String,
        phoneNumber: json['phone_number'] as String?,
        email: json['email'] as String?,
        preferredLanguage: json['preferred_language'] == 'ur'
            ? PreferredLanguage.ur
            : PreferredLanguage.en,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
