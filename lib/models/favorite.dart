class Favorite {
  final String id;
  final String profileId;
  final String favoritedProfileId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.profileId,
    required this.favoritedProfileId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'favorited_profile_id': favoritedProfileId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        favoritedProfileId: json['favorited_profile_id'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
