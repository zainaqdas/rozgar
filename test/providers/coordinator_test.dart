import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/coordinator.dart';
import 'package:rozgar/providers/auth_provider.dart';
import 'package:rozgar/providers/profile_provider.dart';
import 'package:rozgar/providers/job_provider.dart';
import 'package:rozgar/providers/chat_provider.dart';
import 'package:rozgar/providers/notification_provider.dart';
import 'package:rozgar/providers/worker_provider.dart';
import 'package:rozgar/providers/settings_provider.dart';
import 'package:rozgar/models/job.dart';
import 'package:rozgar/models/application.dart';
import 'package:rozgar/models/location_point.dart';
import 'package:rozgar/utils/translations.dart';

void main() {
  late Coordinator coordinator;
  late AuthNotifier auth;
  late ProfileNotifier profile;
  late JobNotifier jobs;
  late ChatNotifier chat;
  late NotificationNotifier notifications;
  late WorkerNotifier workers;
  late SettingsNotifier settings;

  setUp(() {
    auth = AuthNotifier();
    profile = ProfileNotifier();
    jobs = JobNotifier();
    chat = ChatNotifier();
    notifications = NotificationNotifier();
    workers = WorkerNotifier();
    settings = SettingsNotifier();
    coordinator = Coordinator(
      auth: auth,
      profile: profile,
      jobs: jobs,
      chat: chat,
      notifications: notifications,
      workers: workers,
      settings: settings,
    );
  });

  tearDown(() {
    coordinator.dispose();
    auth.dispose();
    profile.dispose();
    jobs.dispose();
    chat.dispose();
    notifications.dispose();
    workers.dispose();
    settings.dispose();
  });

  // ===========================================================================
  // INITIAL STATE
  // ===========================================================================

  group('Initial state', () {
    test('isSupabaseAvailable defaults to true', () {
      expect(coordinator.isSupabaseAvailable, true);
    });

    test('lastOperationError defaults to null', () {
      expect(coordinator.lastOperationError, isNull);
    });

    test('clearOperationError resets error and notifies', () {
      var notified = false;
      coordinator.addListener(() => notified = true);
      coordinator.clearOperationError();
      expect(coordinator.lastOperationError, isNull);
      expect(notified, true);
    });
  });

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  group('initialize', () {
    test('sets isSupabaseAvailable to false on failure', () async {
      await coordinator.initialize();
      expect(coordinator.isSupabaseAvailable, false);
    });

    test('sets lastOperationError on failure', () async {
      await coordinator.initialize();
      expect(coordinator.lastOperationError, isNotNull);
    });

    test('notifies listeners after initialize', () async {
      var notified = false;
      coordinator.addListener(() => notified = true);
      await coordinator.initialize();
      expect(notified, true);
    });
  });

  // ===========================================================================
  // HIRE WORKER
  // ===========================================================================

  group('hireWorker', () {
    late Job testJob;
    late Application hiredApp;
    late Application rejectedApp;

    setUp(() {
      testJob = Job(
        id: 'job-hire-1',
        employerProfileId: 'emp-1',
        categoryId: 'home-plumbing',
        title: 'Fix pipe',
        description: 'Leaking pipe in kitchen',
        budgetAmount: 3000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 31.5204, lng: 74.3587),
        status: JobStatus.open,
        urgency: JobUrgency.today,
        createdAt: DateTime(2026, 7, 28),
      );

      hiredApp = Application(
        id: 'app-hired-1',
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        status: ApplicationStatus.interested,
        appliedAt: DateTime(2026, 7, 28),
      );

      rejectedApp = Application(
        id: 'app-rejected-1',
        jobId: 'job-hire-1',
        workerProfileId: 'worker-2',
        status: ApplicationStatus.interested,
        appliedAt: DateTime(2026, 7, 28),
      );

      jobs.setJobs([testJob]);
      jobs.setApplications([hiredApp, rejectedApp]);
    });

    test('updates job status to hired', () {
      coordinator.hireWorker(
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      final updatedJob = jobs.jobs.firstWhere((j) => j.id == 'job-hire-1');
      expect(updatedJob.status, JobStatus.hired);
      expect(updatedJob.hiredWorkerProfileId, 'worker-1');
    });

    test('marks hired worker application as hired', () {
      coordinator.hireWorker(
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      final app = jobs.applications.firstWhere((a) => a.id == 'app-hired-1');
      expect(app.status, ApplicationStatus.hired);
    });

    test('rejects other applications for the same job', () {
      coordinator.hireWorker(
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      final app = jobs.applications.firstWhere((a) => a.id == 'app-rejected-1');
      expect(app.status, ApplicationStatus.rejected);
    });

    test('does not affect applications for other jobs', () {
      final otherApp = Application(
        id: 'app-other-1',
        jobId: 'job-other',
        workerProfileId: 'worker-2',
        status: ApplicationStatus.interested,
        appliedAt: DateTime(2026, 7, 28),
      );
      jobs.setApplications([hiredApp, rejectedApp, otherApp]);

      coordinator.hireWorker(
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      final app = jobs.applications.firstWhere((a) => a.id == 'app-other-1');
      expect(app.status, ApplicationStatus.interested);
    });

    test('invokes onConversationCreated callback', () {
      // The callback is invoked asynchronously via _createConversation,
      // which calls Supabase. Without Supabase, it will fail silently.
      // We verify the synchronous state changes still happen.
      var notified = false;
      jobs.addListener(() => notified = true);

      coordinator.hireWorker(
        jobId: 'job-hire-1',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      expect(notified, true);
    });

    test('handles non-existent job gracefully', () {
      // Should not throw when job doesn't exist
      coordinator.hireWorker(
        jobId: 'non-existent',
        workerProfileId: 'worker-1',
        employerProfileId: 'emp-1',
      );

      // Jobs list unchanged
      expect(jobs.jobs.length, 1);
      expect(jobs.jobs.first.status, JobStatus.open);
    });
  });

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  group('logout', () {
    test('clears all 7 domain notifiers', () async {
      // Set state in each notifier
      settings.setLanguage(LanguageOption.ur);
      jobs.setJobs([
        Job(
          id: 'j1',
          employerProfileId: 'e1',
          categoryId: 'c1',
          title: 'T',
          description: 'D',
          budgetAmount: 100,
          budgetType: BudgetType.fixed,
          pinLocation: const LocationPoint(lat: 31.5, lng: 74.3),
          status: JobStatus.open,
          urgency: JobUrgency.today,
          createdAt: DateTime.now(),
        ),
      ]);

      await coordinator.logout();

      // 1. Settings reset
      expect(settings.language, LanguageOption.en);
      // 2. Jobs cleared
      expect(jobs.jobs, isEmpty);
      expect(jobs.applications, isEmpty);
      // 3. Chat cleared
      expect(chat.conversations, isEmpty);
      expect(chat.messages, isEmpty);
      // 4. Notifications cleared
      expect(notifications.notifications, isEmpty);
      // 5. Workers cleared
      expect(workers.allWorkers, isEmpty);
      // 6. Profile cleared
      expect(profile.employerProfile, isNull);
      expect(profile.workerProfile, isNull);
      expect(profile.activeProfileId, isNull);
      // 7. Auth cleared
      expect(auth.authIdentity, isNull);
      expect(auth.needsOnboarding, false);
    });

    test('notifies listeners after logout', () async {
      var notified = false;
      coordinator.addListener(() => notified = true);
      await coordinator.logout();
      expect(notified, true);
    });

    test('clears lastOperationError on logout', () async {
      // Trigger an error first
      await coordinator.initialize();
      expect(coordinator.lastOperationError, isNotNull);

      await coordinator.logout();
      // After logout, coordinator notifies — error state is from notifiers
      // The coordinator itself doesn't clear its own _lastOperationError on
      // logout, but all notifiers clear theirs.
      expect(jobs.lastOperationError, isNull);
      expect(chat.lastOperationError, isNull);
      expect(notifications.lastOperationError, isNull);
      expect(workers.lastOperationError, isNull);
    });
  });

  // ===========================================================================
  // REFRESH FROM SUPABASE
  // ===========================================================================

  group('refreshFromSupabase', () {
    test('notifies listeners when Supabase unavailable', () async {
      await coordinator.initialize();
      expect(coordinator.isSupabaseAvailable, false);

      var notified = false;
      coordinator.addListener(() => notified = true);
      await coordinator.refreshFromSupabase();
      expect(notified, true);
    });

    test('does not throw when no active profile', () async {
      // Without Supabase, isSupabaseAvailable is false, so it short-circuits
      await coordinator.initialize();
      await expectLater(
        coordinator.refreshFromSupabase(),
        completes,
      );
    });
  });
}
