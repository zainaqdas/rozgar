import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/job.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  group('Job', () {
    final pinLocation = const LocationPoint(lat: 31.5204, lng: 74.3587, address: 'Gulberg III, Lahore');

    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final job = Job(
        id: 'job-101',
        employerProfileId: 'profile-emp-1',
        categoryId: 'home-electrical',
        title: 'Short Circuit Repair',
        description: 'Need an electrician for short circuit.',
        aiExtractedSummary: AIExtractedSummary(
          category: 'Electrical Work',
          urgency: JobUrgency.instant,
          suggestedBudget: 2500,
          estimatedDuration: 2,
          requiredSkills: ['Wiring', 'Breaker Repair'],
        ),
        budgetAmount: 2500,
        budgetType: BudgetType.fixed,
        pinLocation: pinLocation,
        status: JobStatus.open,
        urgency: JobUrgency.instant,
        createdAt: now,
        hiredWorkerProfileId: null,
      );

      final json = job.toJson();
      final restored = Job.fromJson(json);

      expect(restored.id, 'job-101');
      expect(restored.title, 'Short Circuit Repair');
      expect(restored.budgetAmount, 2500);
      expect(restored.status, JobStatus.open);
      expect(restored.urgency, JobUrgency.instant);
      expect(restored.aiExtractedSummary?.category, 'Electrical Work');
    });

    test('copyWith updates status', () {
      final now = DateTime.now();
      final job = Job(
        id: 'job-102',
        employerProfileId: 'profile-emp-1',
        categoryId: 'home-plumbing',
        pinLocation: pinLocation,
        createdAt: now,
      );

      final hired = job.copyWith(
        status: JobStatus.hired,
        hiredWorkerProfileId: 'profile-wrk-1',
      );
      expect(hired.status, JobStatus.hired);
      expect(hired.hiredWorkerProfileId, 'profile-wrk-1');
      expect(hired.id, 'job-102'); // unchanged
    });

    test('parses all job statuses', () {
      final now = DateTime.now();
      final base = {
        'id': 'job-test',
        'employer_profile_id': 'emp-1',
        'category_id': 'cat-1',
        'pin_location': {'lat': 31.5, 'lng': 74.3, 'address': 'Test'},
        'created_at': now.toIso8601String(),
      };

      for (final status in ['open', 'hired', 'completed', 'cancelled', 'expired']) {
        final json = {...base, 'status': status};
        final job = Job.fromJson(json);
        expect(job.status.name, status);
      }
    });

    test('parses all urgency levels', () {
      final now = DateTime.now();
      final base = {
        'id': 'job-test',
        'employer_profile_id': 'emp-1',
        'category_id': 'cat-1',
        'pin_location': {'lat': 31.5, 'lng': 74.3, 'address': 'Test'},
        'created_at': now.toIso8601String(),
      };

      final instant = Job.fromJson({...base, 'urgency': 'instant'});
      expect(instant.urgency, JobUrgency.instant);

      final scheduled = Job.fromJson({...base, 'urgency': 'scheduled'});
      expect(scheduled.urgency, JobUrgency.scheduled);

      final today = Job.fromJson({...base, 'urgency': 'today'});
      expect(today.urgency, JobUrgency.today);
    });
  });

  group('AIExtractedSummary', () {
    test('toJson and fromJson round-trip', () {
      final summary = AIExtractedSummary(
        category: 'Plumbing',
        urgency: JobUrgency.today,
        suggestedBudget: 3500,
        estimatedDuration: 3,
        requiredSkills: ['Pipe Fitting', 'Motor Rewinding'],
      );

      final json = {
        'category': summary.category,
        'urgency': summary.urgency.name,
        'suggested_budget': summary.suggestedBudget,
        'estimated_duration': summary.estimatedDuration,
        'required_skills': summary.requiredSkills,
      };

      final restored = AIExtractedSummary.fromJson(json);
      expect(restored.category, 'Plumbing');
      expect(restored.urgency, JobUrgency.today);
      expect(restored.suggestedBudget, 3500);
      expect(restored.requiredSkills, ['Pipe Fitting', 'Motor Rewinding']);
    });
  });
}
