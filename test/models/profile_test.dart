import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/profile.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  group('Profile', () {
    final homeLocation = const LocationPoint(lat: 31.5204, lng: 74.3587, address: 'Gulberg, Lahore', city: 'Lahore');
    final now = DateTime.now();

    test('toJson and fromJson round-trip', () {
      final profile = Profile(
        id: 'profile-1',
        authIdentityId: 'auth-1',
        profileType: ProfileType.employer,
        displayName: 'Tariq Mahmood',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        phone: '+92 300 1234567',
        city: 'Lahore',
        homeLocation: homeLocation,
        createdAt: now,
        isVerified: true,
        idVerificationStatus: IdVerificationStatus.verified,
        accountStatus: AccountStatus.active,
        onboardingCompletionPct: 100,
      );

      final json = profile.toJson();
      final restored = Profile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.authIdentityId, profile.authIdentityId);
      expect(restored.profileType, ProfileType.employer);
      expect(restored.displayName, profile.displayName);
      expect(restored.phone, profile.phone);
      expect(restored.isVerified, true);
    });

    test('worker profile type parsing', () {
      final json = {
        'id': 'profile-2',
        'auth_identity_id': 'auth-2',
        'profile_type': 'worker',
        'display_name': 'Muhammad Usman',
        'profile_photo_url': '',
        'city': 'Lahore',
        'home_location': {'lat': 31.5, 'lng': 74.3, 'address': '', 'city': 'Lahore'},
        'created_at': now.toIso8601String(),
        'is_verified': false,
        'id_verification_status': 'none',
        'account_status': 'active',
        'onboarding_completion_pct': 90,
      };

      final profile = Profile.fromJson(json);
      expect(profile.profileType, ProfileType.worker);
      expect(profile.idVerificationStatus, IdVerificationStatus.none);
      expect(profile.onboardingCompletionPct, 90);
    });

    test('copyWith updates fields correctly', () {
      final profile = Profile(
        id: 'profile-3',
        authIdentityId: 'auth-3',
        profileType: ProfileType.employer,
        homeLocation: homeLocation,
        createdAt: now,
      );

      final updated = profile.copyWith(displayName: 'Updated Name', isVerified: true);
      expect(updated.displayName, 'Updated Name');
      expect(updated.isVerified, true);
      expect(updated.id, profile.id); // unchanged
    });

    test('default values are correct', () {
      final profile = Profile(
        id: 'profile-4',
        authIdentityId: 'auth-4',
        profileType: ProfileType.worker,
        homeLocation: homeLocation,
        createdAt: now,
      );

      expect(profile.displayName, '');
      expect(profile.isVerified, false);
      expect(profile.idVerificationStatus, IdVerificationStatus.none);
      expect(profile.accountStatus, AccountStatus.active);
      expect(profile.onboardingCompletionPct, 0);
    });
  });

  group('WorkerDetails', () {
    final currentLocation = const LocationPoint(lat: 31.522, lng: 74.356, address: 'Liberty Market, Lahore');

    test('toJson and fromJson round-trip', () {
      final details = WorkerDetails(
        profileId: 'profile-wrk-1',
        categoryIds: ['home-electrical', 'ac-appliance'],
        bio: 'Experienced electrician',
        yearsExperience: 8,
        rateNote: 'Rs. 1,500 visiting fee',
        availabilityStatus: AvailabilityStatus.today,
        notificationRadiusKm: 15,
        isOnlineForMap: true,
        currentLocation: currentLocation,
        portfolioMedia: ['https://example.com/img1.jpg'],
        averageRating: 4.9,
        totalJobsCompleted: 42,
        responseTimeAvgMinutes: 4,
        isFeatured: true,
      );

      final json = details.toJson();
      final restored = WorkerDetails.fromJson(json);

      expect(restored.profileId, details.profileId);
      expect(restored.categoryIds, ['home-electrical', 'ac-appliance']);
      expect(restored.bio, details.bio);
      expect(restored.yearsExperience, 8);
      expect(restored.averageRating, 4.9);
      expect(restored.totalJobsCompleted, 42);
      expect(restored.isFeatured, true);
    });

    test('copyWith updates fields correctly', () {
      final details = WorkerDetails(
        profileId: 'profile-wrk-2',
        currentLocation: currentLocation,
      );

      final updated = details.copyWith(bio: 'New bio', isOnlineForMap: false);
      expect(updated.bio, 'New bio');
      expect(updated.isOnlineForMap, false);
      expect(updated.profileId, 'profile-wrk-2'); // unchanged
    });
  });
}
