import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/application.dart';

void main() {
  group('Application', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final app = Application(
        id: 'app-101',
        jobId: 'job-101',
        workerProfileId: 'profile-wrk-1',
        status: ApplicationStatus.interested,
        appliedAt: now,
        message: 'I can do the job!',
        aiMatchNote: '⚡ Top match!',
      );

      final json = app.toJson();
      final restored = Application.fromJson(json);

      expect(restored.id, 'app-101');
      expect(restored.jobId, 'job-101');
      expect(restored.status, ApplicationStatus.interested);
      expect(restored.message, 'I can do the job!');
    });

    test('parses all application statuses', () {
      final now = DateTime.now();
      final base = {
        'id': 'app-test',
        'job_id': 'job-1',
        'worker_profile_id': 'wrk-1',
        'applied_at': now.toIso8601String(),
      };

      final interested = Application.fromJson({...base, 'status': 'interested'});
      expect(interested.status, ApplicationStatus.interested);

      final hired = Application.fromJson({...base, 'status': 'hired'});
      expect(hired.status, ApplicationStatus.hired);

      final rejected = Application.fromJson({...base, 'status': 'rejected'});
      expect(rejected.status, ApplicationStatus.rejected);
    });

    test('copyWith updates status', () {
      final now = DateTime.now();
      final app = Application(
        id: 'app-1',
        jobId: 'job-1',
        workerProfileId: 'wrk-1',
        appliedAt: now,
      );

      final updated = app.copyWith(status: ApplicationStatus.hired);
      expect(updated.status, ApplicationStatus.hired);
      expect(updated.id, 'app-1');
    });
  });
}
