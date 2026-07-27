class Review {
  final String id;
  final String jobId;
  final String reviewerProfileId;
  final String revieweeProfileId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.jobId,
    required this.reviewerProfileId,
    required this.revieweeProfileId,
    this.rating = 5,
    this.comment = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'reviewer_profile_id': reviewerProfileId,
        'reviewee_profile_id': revieweeProfileId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        reviewerProfileId: json['reviewer_profile_id'] as String,
        revieweeProfileId: json['reviewee_profile_id'] as String,
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
