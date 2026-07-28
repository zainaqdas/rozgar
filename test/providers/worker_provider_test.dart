import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/worker_provider.dart';
import 'package:rozgar/models/profile.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  late WorkerNotifier notifier;

  group('WorkerNotifier initial state', () {
    setUp(() {
      notifier = WorkerNotifier();
    });

    test('allWorkers is empty', () {
      expect(notifier.allWorkers, isEmpty);
      expect(notifier.lastOperationError, isNull);
    });

    test('setWorkers replaces worker list', () {
      final worker = WorkerEntry(
        profile: Profile(
          id: 'wrk-1',
          authIdentityId: 'auth-1',
          profileType: ProfileType.worker,
          displayName: 'Usman',
          homeLocation: const LocationPoint(lat: 31.52, lng: 74.36),
          createdAt: DateTime.now(),
        ),
        details: WorkerDetails(
          profileId: 'wrk-1',
          categoryIds: ['electrician'],
          bio: 'Expert',
          yearsExperience: 5,
          rateNote: '',
          availabilityStatus: AvailabilityStatus.today,
          notificationRadiusKm: 15,
          isOnlineForMap: true,
          currentLocation: const LocationPoint(lat: 31.5204, lng: 74.3587),
          averageRating: 4.5,
          totalJobsCompleted: 10,
          responseTimeAvgMinutes: 5,
        ),
      );

      notifier.setWorkers([worker]);
      expect(notifier.allWorkers.length, 1);
      expect(notifier.allWorkers[0].profile.displayName, 'Usman');
    });
  });

  group('WorkerNotifier getPublicProfile', () {
    setUp(() {
      notifier = WorkerNotifier();
    });

    test('returns null for unknown profile', () {
      final result = notifier.getPublicProfile('unknown', null, null);
      expect(result, isNull);
    });

    test('returns self profile when matching', () {
      final selfProfile = Profile(
        id: 'wrk-1',
        authIdentityId: 'auth-1',
        profileType: ProfileType.worker,
        displayName: 'Usman',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36),
        createdAt: DateTime.now(),
      );
      final selfDetails = WorkerDetails(
        profileId: 'wrk-1',
        categoryIds: ['electrician'],
        bio: 'Expert',
        yearsExperience: 5,
        rateNote: '',
        availabilityStatus: AvailabilityStatus.today,
        notificationRadiusKm: 15,
        isOnlineForMap: true,
        currentLocation: const LocationPoint(lat: 31.5204, lng: 74.3587),
        averageRating: 4.5,
        totalJobsCompleted: 10,
        responseTimeAvgMinutes: 5,
      );

      final result = notifier.getPublicProfile('wrk-1', selfProfile, selfDetails);
      expect(result, isNotNull);
      expect(result!.profile.displayName, 'Usman');
      expect(result.workerDetails, isNotNull);
    });
  });
}
