/// Lightweight model for the nearby_workers PostGIS RPC result.
/// Contains only the fields needed for map markers and the bottom sheet.
class NearbyWorker {
  final String profileId;
  final String displayName;
  final List<String> categoryIds;
  final String bio;
  final double averageRating;
  final int totalJobsCompleted;
  final double distanceKm;
  final double lat;
  final double lng;
  final String profilePhotoUrl;

  const NearbyWorker({
    required this.profileId,
    required this.displayName,
    this.categoryIds = const [],
    this.bio = '',
    this.averageRating = 5.0,
    this.totalJobsCompleted = 0,
    this.distanceKm = 0,
    required this.lat,
    required this.lng,
    this.profilePhotoUrl = '',
  });

  factory NearbyWorker.fromJson(Map<String, dynamic> json) => NearbyWorker(
        profileId: json['profile_id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        categoryIds: (json['category_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        bio: json['bio'] as String? ?? '',
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
        totalJobsCompleted:
            (json['total_jobs_completed'] as num?)?.toInt() ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      );
}
