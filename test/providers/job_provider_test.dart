import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/job_provider.dart';
import 'package:rozgar/models/job.dart';
import 'package:rozgar/models/application.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  late JobNotifier notifier;

  final lahoreLocation = const LocationPoint(lat: 31.5204, lng: 74.3587);
  final nearbyLocation = const LocationPoint(lat: 31.5250, lng: 74.3600);
  final farLocation = const LocationPoint(lat: 32.0000, lng: 75.0000);

  Job makeJob({
    String id = 'job-1',
    String employerId = 'emp-1',
    JobStatus status = JobStatus.open,
    LocationPoint? location,
    String categoryId = 'electrician',
  }) =>
      Job(
        id: id,
        employerProfileId: employerId,
        categoryId: categoryId,
        title: 'Fix wiring',
        description: 'Need electrician for house wiring',
        budgetAmount: 5000,
        budgetType: BudgetType.fixed,
        pinLocation: location ?? lahoreLocation,
        status: status,
        urgency: JobUrgency.today,
        createdAt: DateTime.now(),
      );

  setUp(() {
    notifier = JobNotifier();
  });

  group('JobNotifier initial state', () {
    test('jobs is empty', () {
      expect(notifier.jobs, isEmpty);
    });

    test('applications is empty', () {
      expect(notifier.applications, isEmpty);
    });

    test('lastOperationError is null', () {
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('JobNotifier setJobs', () {
    test('replaces job list', () {
      notifier.setJobs([makeJob(), makeJob(id: 'job-2')]);
      expect(notifier.jobs.length, 2);
    });
  });

  group('JobNotifier setApplications', () {
    test('replaces application list', () {
      final apps = [
        Application(
          id: 'app-1',
          jobId: 'job-1',
          workerProfileId: 'wrk-1',
          status: ApplicationStatus.interested,
          appliedAt: DateTime.now(),
        ),
      ];
      notifier.setApplications(apps);
      expect(notifier.applications.length, 1);
    });
  });

  group('JobNotifier getEmployerJobs', () {
    test('returns jobs for specific employer', () {
      notifier.setJobs([
        makeJob(id: 'job-1', employerId: 'emp-1'),
        makeJob(id: 'job-2', employerId: 'emp-2'),
        makeJob(id: 'job-3', employerId: 'emp-1'),
      ]);
      final result = notifier.getEmployerJobs('emp-1');
      expect(result.length, 2);
    });

    test('returns empty for unknown employer', () {
      notifier.setJobs([makeJob()]);
      final result = notifier.getEmployerJobs('unknown');
      expect(result, isEmpty);
    });
  });

  group('JobNotifier getJobsNearWorker', () {
    test('returns open jobs within radius', () {
      notifier.setJobs([
        makeJob(id: 'job-1', location: nearbyLocation),
        makeJob(id: 'job-2', location: farLocation),
      ]);
      final result = notifier.getJobsNearWorker(
        workerLocation: lahoreLocation,
        radiusKm: 15,
        categoryIds: [],
      );
      expect(result.length, 1);
      expect(result[0].id, 'job-1');
    });

    test('excludes non-open jobs', () {
      notifier.setJobs([
        makeJob(id: 'job-1', status: JobStatus.hired, location: nearbyLocation),
      ]);
      final result = notifier.getJobsNearWorker(
        workerLocation: lahoreLocation,
        radiusKm: 15,
        categoryIds: [],
      );
      expect(result, isEmpty);
    });

    test('filters by category when provided', () {
      notifier.setJobs([
        makeJob(id: 'job-1', categoryId: 'electrician', location: nearbyLocation),
        makeJob(id: 'job-2', categoryId: 'plumbing', location: nearbyLocation),
      ]);
      final result = notifier.getJobsNearWorker(
        workerLocation: lahoreLocation,
        radiusKm: 15,
        categoryIds: ['electrician'],
      );
      expect(result.length, 1);
      expect(result[0].categoryId, 'electrician');
    });
  });

  group('JobNotifier expressInterest', () {
    test('creates application for worker', () {
      notifier.setJobs([makeJob()]);
      notifier.expressInterest(
        'job-1',
        workerProfileId: 'wrk-1',
        workerDisplayName: 'Usman',
      );
      expect(notifier.applications.length, 1);
      expect(notifier.applications[0].jobId, 'job-1');
      expect(notifier.applications[0].workerProfileId, 'wrk-1');
      expect(notifier.applications[0].status, ApplicationStatus.interested);
    });

    test('prevents duplicate applications', () {
      notifier.setJobs([makeJob()]);
      notifier.expressInterest(
        'job-1',
        workerProfileId: 'wrk-1',
        workerDisplayName: 'Usman',
      );
      notifier.expressInterest(
        'job-1',
        workerProfileId: 'wrk-1',
        workerDisplayName: 'Usman',
      );
      expect(notifier.applications.length, 1);
    });
  });

  group('JobNotifier clear', () {
    test('resets all state', () {
      notifier.setJobs([makeJob()]);
      notifier.setApplications([
        Application(
          id: 'app-1',
          jobId: 'job-1',
          workerProfileId: 'wrk-1',
          status: ApplicationStatus.interested,
          appliedAt: DateTime.now(),
        ),
      ]);
      notifier.clear();
      expect(notifier.jobs, isEmpty);
      expect(notifier.applications, isEmpty);
      expect(notifier.lastOperationError, isNull);
    });
  });
}
