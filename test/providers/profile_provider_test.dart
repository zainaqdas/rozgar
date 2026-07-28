import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/profile_provider.dart';
import 'package:rozgar/models/profile.dart';
import 'package:rozgar/models/location_point.dart';
import 'package:rozgar/models/review.dart';

void main() {
  late ProfileNotifier notifier;

  final testLocation = const LocationPoint(lat: 31.5204, lng: 74.3587);

  Profile makeEmployer() => Profile(
        id: 'emp-1',
        authIdentityId: 'auth-1',
        profileType: ProfileType.employer,
        displayName: 'Ahmed',
        homeLocation: testLocation,
        createdAt: DateTime.now(),
      );

  Profile makeWorker() => Profile(
        id: 'wrk-1',
        authIdentityId: 'auth-1',
        profileType: ProfileType.worker,
        displayName: 'Usman',
        homeLocation: testLocation,
        createdAt: DateTime.now(),
      );

  WorkerDetails makeWorkerDetails() => WorkerDetails(
        profileId: 'wrk-1',
        categoryIds: ['electrician'],
        bio: 'Expert electrician',
        yearsExperience: 5,
        rateNote: 'Rs 500/hr',
        availabilityStatus: AvailabilityStatus.today,
        notificationRadiusKm: 15,
        isOnlineForMap: true,
        currentLocation: testLocation,
        averageRating: 4.5,
        totalJobsCompleted: 10,
        responseTimeAvgMinutes: 5,
      );

  setUp(() {
    notifier = ProfileNotifier();
  });

  group('ProfileNotifier initial state', () {
    test('all profiles are null', () {
      expect(notifier.employerProfile, isNull);
      expect(notifier.workerProfile, isNull);
      expect(notifier.workerDetails, isNull);
      expect(notifier.activeProfileId, isNull);
      expect(notifier.activeProfile, isNull);
    });

    test('reviews is empty', () {
      expect(notifier.reviews, isEmpty);
    });

    test('activeProfileType defaults to employer', () {
      expect(notifier.activeProfileType, ProfileType.employer);
    });
  });

  group('ProfileNotifier setProfiles', () {
    test('sets employer and worker profiles', () {
      notifier.setProfiles([makeEmployer(), makeWorker()], makeWorkerDetails());
      expect(notifier.employerProfile, isNotNull);
      expect(notifier.workerProfile, isNotNull);
      expect(notifier.workerDetails, isNotNull);
    });

    test('defaults activeProfileId to employer', () {
      notifier.setProfiles([makeEmployer(), makeWorker()], makeWorkerDetails());
      expect(notifier.activeProfileId, 'emp-1');
      expect(notifier.activeProfileType, ProfileType.employer);
    });

    test('sets activeProfileId to worker if no employer', () {
      notifier.setProfiles([makeWorker()], makeWorkerDetails());
      expect(notifier.activeProfileId, 'wrk-1');
      expect(notifier.activeProfileType, ProfileType.worker);
    });
  });

  group('ProfileNotifier switchProfile', () {
    test('switches to worker profile', () {
      notifier.setProfiles([makeEmployer(), makeWorker()], makeWorkerDetails());
      notifier.switchProfile(ProfileType.worker);
      expect(notifier.activeProfileType, ProfileType.worker);
      expect(notifier.activeProfile!.displayName, 'Usman');
    });

    test('switches back to employer profile', () {
      notifier.setProfiles([makeEmployer(), makeWorker()], makeWorkerDetails());
      notifier.switchProfile(ProfileType.worker);
      notifier.switchProfile(ProfileType.employer);
      expect(notifier.activeProfileType, ProfileType.employer);
      expect(notifier.activeProfile!.displayName, 'Ahmed');
    });

    test('ignores switch to unavailable profile type', () {
      notifier.setProfiles([makeEmployer()], null);
      notifier.switchProfile(ProfileType.worker);
      // Should stay on employer since no worker profile exists
      expect(notifier.activeProfileType, ProfileType.employer);
    });
  });

  group('ProfileNotifier reviews', () {
    test('setReviews replaces list', () {
      final reviews = [
        Review(
          id: 'rev-1',
          jobId: 'job-1',
          reviewerProfileId: 'emp-1',
          revieweeProfileId: 'wrk-1',
          rating: 5,
          comment: 'Great work!',
          createdAt: DateTime.now(),
        ),
      ];
      notifier.setReviews(reviews);
      expect(notifier.reviews.length, 1);
      expect(notifier.reviews[0].rating, 5);
    });
  });

  group('ProfileNotifier toggleWorkerOnline', () {
    test('toggles online status', () {
      notifier.setProfiles([makeWorker()], makeWorkerDetails());
      expect(notifier.workerDetails!.isOnlineForMap, isTrue);
      notifier.toggleWorkerOnline(false);
      expect(notifier.workerDetails!.isOnlineForMap, isFalse);
    });

    test('does nothing without worker details', () {
      notifier.toggleWorkerOnline(true);
      expect(notifier.workerDetails, isNull);
    });
  });

  group('ProfileNotifier updateWorkerRadius', () {
    test('updates radius', () {
      notifier.setProfiles([makeWorker()], makeWorkerDetails());
      notifier.updateWorkerRadius(25);
      expect(notifier.workerDetails!.notificationRadiusKm, 25);
    });
  });

  group('ProfileNotifier clear', () {
    test('resets all state', () {
      notifier.setProfiles([makeEmployer(), makeWorker()], makeWorkerDetails());
      notifier.setReviews([
        Review(
          id: 'rev-1',
          jobId: 'job-1',
          reviewerProfileId: 'emp-1',
          revieweeProfileId: 'wrk-1',
          rating: 5,
          comment: 'Great!',
          createdAt: DateTime.now(),
        ),
      ]);
      notifier.clear();
      expect(notifier.employerProfile, isNull);
      expect(notifier.workerProfile, isNull);
      expect(notifier.workerDetails, isNull);
      expect(notifier.activeProfileId, isNull);
      expect(notifier.reviews, isEmpty);
    });
  });
}
