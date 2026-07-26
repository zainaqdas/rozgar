import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/review.dart';

void main() {
  group('Review', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final review = Review(
        id: 'rev-1',
        jobId: 'job-101',
        reviewerProfileId: 'profile-emp-1',
        revieweeProfileId: 'profile-wrk-1',
        rating: 5,
        comment: 'Excellent work!',
        createdAt: now,
      );

      final json = review.toJson();
      final restored = Review.fromJson(json);

      expect(restored.id, 'rev-1');
      expect(restored.rating, 5);
      expect(restored.comment, 'Excellent work!');
      expect(restored.reviewerProfileId, 'profile-emp-1');
    });

    test('default rating is 5', () {
      final now = DateTime.now();
      final review = Review(
        id: 'rev-2',
        jobId: 'job-1',
        reviewerProfileId: 'r1',
        revieweeProfileId: 'r2',
        createdAt: now,
      );

      expect(review.rating, 5);
      expect(review.comment, '');
    });

    test('parses rating correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'rev-3',
        'job_id': 'job-1',
        'reviewer_profile_id': 'r1',
        'reviewee_profile_id': 'r2',
        'rating': 3,
        'comment': 'Average',
        'created_at': now.toIso8601String(),
      };

      final review = Review.fromJson(json);
      expect(review.rating, 3);
    });
  });
}
