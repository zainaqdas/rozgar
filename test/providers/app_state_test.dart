import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/app_state.dart';
import 'package:rozgar/utils/translations.dart';
import 'package:rozgar/models/profile.dart';
import 'package:rozgar/models/job.dart';
import 'package:rozgar/models/location_point.dart';
import 'package:rozgar/models/application.dart';


void main() {
  late AppState appState;

  group('Initial state', () {
    setUp(() {
      appState = AppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('all values are null or empty before initialization', () {
      expect(appState.authIdentity, isNull);
      expect(appState.employerProfile, isNull);
      expect(appState.workerProfile, isNull);
      expect(appState.activeProfile, isNull);
      expect(appState.jobs, isEmpty);
      expect(appState.applications, isEmpty);
      expect(appState.conversations, isEmpty);
      expect(appState.messages, isEmpty);
      expect(appState.reviews, isEmpty);
      expect(appState.notifications, isEmpty);
      expect(appState.allWorkers, isEmpty);
      expect(appState.isSupabaseAvailable, true);
    });

    test('default language is English', () {
      expect(appState.language, LanguageOption.en);
    });

    test('activeProfileType defaults to employer', () {
      expect(appState.activeProfileType, ProfileType.employer);
    });
  });

  group('After initialization without session', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
    });

    tearDown(() {
      appState.dispose();
    });

    test('isSupabaseAvailable is false', () {
      expect(appState.isSupabaseAvailable, false);
    });

    test('all state is empty after failed init', () {
      expect(appState.authIdentity, isNull);
      expect(appState.jobs, isEmpty);
      expect(appState.applications, isEmpty);
      expect(appState.conversations, isEmpty);
    });
  });

  group('Language switching', () {
    setUp(() {
      appState = AppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('switches to Urdu and back to English', () {
      appState.setLanguage(LanguageOption.ur);
      expect(appState.language, LanguageOption.ur);

      appState.setLanguage(LanguageOption.en);
      expect(appState.language, LanguageOption.en);
    });
  });

  group('Login and auth', () {
    setUp(() {
      appState = AppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('loginWithPhoneOrEmail sets auth identity', () {
      appState.loginWithPhoneOrEmail('+92 300 1234567');
      expect(appState.authIdentity, isNotNull);
      expect(appState.authIdentity!.phoneNumber, contains('+92'));
    });

    test('loginWithEmail sets auth identity', () {
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      expect(appState.authIdentity, isNotNull);
      expect(appState.authIdentity!.email, 'test@rozgar.pk');
    });

    test('verifyOtp returns true', () {
      expect(appState.verifyOtp('123456'), true);
    });
  });

  group('Profile switching', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
    });

    tearDown(() {
      appState.dispose();
    });

    test('can switch profiles when both exist', () {
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );

      appState.switchProfile(ProfileType.employer);
      expect(appState.activeProfileType, ProfileType.employer);

      appState.switchProfile(ProfileType.worker);
      expect(appState.activeProfileType, ProfileType.worker);
      expect(appState.activeProfile?.id, appState.workerProfile?.id);

      appState.switchProfile(ProfileType.employer);
      expect(appState.activeProfileType, ProfileType.employer);
      expect(appState.activeProfile?.id, appState.employerProfile?.id);
    });
  });

  group('Job operations', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('addJob adds a job to the list', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test Location');

      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test description',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );

      expect(appState.jobs.length, 1);
      expect(appState.jobs.first.title, 'Test Job');
    });

    test('expressInterest creates application and notification', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test');
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );
      appState.switchProfile(ProfileType.worker);

      final openJob = appState.jobs.where((j) => j.status == JobStatus.open).first;
      final initialApps = appState.applications.length;

      appState.expressInterest(openJob.id);

      expect(appState.applications.length, initialApps + 1);
      expect(appState.notifications.length, 1);
    });

    test('hireWorker updates job status', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test');
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );
      appState.switchProfile(ProfileType.worker);
      appState.expressInterest(appState.jobs.first.id);
      appState.switchProfile(ProfileType.employer);

      final openJob = appState.jobs.where((j) => j.status == JobStatus.open).first;
      final workerId = appState.workerProfile!.id;

      appState.hireWorker(openJob.id, workerId);

      final hiredJob = appState.jobs.where((j) => j.id == openJob.id).first;
      expect(hiredJob.status, JobStatus.hired);
      expect(hiredJob.hiredWorkerProfileId, workerId);

      final app = appState.applications.where((a) => a.jobId == openJob.id).first;
      expect(app.status, ApplicationStatus.hired);
    });

    test('completeJob sets job to completed', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test');
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );

      appState.completeJob(appState.jobs.first.id);

      final completedJob = appState.jobs.first;
      expect(completedJob.status, JobStatus.completed);
    });

    test('getEmployerJobs returns only employer jobs', () {
      final empJobs = appState.getEmployerJobs();
      expect(empJobs, isEmpty);

      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
        urgency: JobUrgency.today,
      );

      expect(appState.getEmployerJobs().length, 1);
    });
  });

  group('Message operations', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('sendMessage adds message and updates conversation', () {
      final conv = appState.getOrCreateConversation('job-test', appState.workerProfile!.id);
      final initialMsgs = appState.messages.length;

      appState.sendMessage(conv.id, 'Test message');

      expect(appState.messages.length, initialMsgs + 1);
      expect(appState.messages.last.content, 'Test message');

      final updatedConv = appState.conversations.where((c) => c.id == conv.id).first;
      expect(updatedConv.lastMessageText, 'Test message');
    });
  });

  group('Worker settings', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('toggleWorkerOnline updates online status', () {
      final initial = appState.workerDetails!.isOnlineForMap;

      appState.toggleWorkerOnline(!initial);
      expect(appState.workerDetails!.isOnlineForMap, !initial);

      appState.toggleWorkerOnline(initial);
      expect(appState.workerDetails!.isOnlineForMap, initial);
    });

    test('updateWorkerRadius updates radius', () {
      appState.updateWorkerRadius(20);
      expect(appState.workerDetails!.notificationRadiusKm, 20);

      appState.updateWorkerRadius(5);
      expect(appState.workerDetails!.notificationRadiusKm, 5);
    });
  });

  group('Review operations', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('addReview adds a review to the list', () {
      appState.addReview('job-test', appState.workerProfile!.id, 5, 'Great work!');

      expect(appState.reviews.length, 1);
      expect(appState.reviews.first.rating, 5);
      expect(appState.reviews.first.comment, 'Great work!');
    });
  });

  group('Notification operations', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('markNotificationsRead marks all as read', () {
      expect(appState.notifications, isEmpty);

      appState.markNotificationsRead();
      expect(appState.notifications, isEmpty);
    });
  });

  group('Workers', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('allWorkers includes logged-in worker', () {
      final workers = appState.allWorkers;
      expect(workers.length, 1);
      expect(workers.any((w) => w.profile.id == appState.workerProfile?.id), true);
    });
  });

  group('Onboarding', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
    });

    tearDown(() {
      appState.dispose();
    });

    test('completeWorkerOnboarding creates worker profile', () {
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test Location'),
      );

      expect(appState.workerProfile, isNotNull);
      expect(appState.workerProfile!.displayName, 'Test Worker');
      expect(appState.activeProfileType, ProfileType.worker);
    });

    test('completeEmployerOnboarding creates employer profile', () {
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test Location'),
      );

      expect(appState.employerProfile, isNotNull);
      expect(appState.employerProfile!.displayName, 'Test Employer');
      expect(appState.activeProfileType, ProfileType.employer);
    });
  });

  group('Logout', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('logout clears all state', () async {
      await appState.logout();

      expect(appState.authIdentity, isNull);
      expect(appState.employerProfile, isNull);
      expect(appState.workerProfile, isNull);
      expect(appState.activeProfile, isNull);
      expect(appState.jobs, isEmpty);
      expect(appState.applications, isEmpty);
      expect(appState.conversations, isEmpty);
      expect(appState.messages, isEmpty);
      expect(appState.reviews, isEmpty);
      expect(appState.notifications, isEmpty);
    });

    test('logout does not throw when called twice', () async {
      await appState.logout();
      await appState.logout();
      expect(appState.authIdentity, isNull);
    });
  });

  group('Error surfacing', () {
    setUp(() {
      appState = AppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('clearOperationError resets lastOperationError to null', () {
      expect(appState.lastOperationError, isNull);
      appState.clearOperationError();
      expect(appState.lastOperationError, isNull);
    });
  });

  group('getJobsNearWorker', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('returns jobs within radius and matching categories', () {
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-electrical',
        title: 'Electrical Repair',
        description: 'Fix wiring',
        budgetAmount: 5000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Lahore'),
        urgency: JobUrgency.today,
      );
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'plumbing',
        title: 'Pipe Repair',
        description: 'Fix pipe',
        budgetAmount: 3000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Lahore'),
        urgency: JobUrgency.scheduled,
      );

      final nearby = appState.getJobsNearWorker(
        workerLocation: const LocationPoint(lat: 31.52, lng: 74.36),
        radiusKm: 10,
        categoryIds: ['home-electrical'],
      );

      expect(nearby.length, 1);
      expect(nearby.first.title, 'Electrical Repair');
    });

    test('returns empty when no jobs match radius', () {
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-electrical',
        title: 'Far Job',
        description: 'Far away',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 33.68, lng: 73.05, address: 'Islamabad'),
        urgency: JobUrgency.today,
      );

      final nearby = appState.getJobsNearWorker(
        workerLocation: const LocationPoint(lat: 31.52, lng: 74.36),
        radiusKm: 10,
        categoryIds: [],
      );

      expect(nearby, isEmpty);
    });

    test('excludes hired and completed jobs', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test');
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Open Job',
        description: 'Still open',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );
      final jobId = appState.jobs.first.id;
      appState.completeJob(jobId);

      final nearby = appState.getJobsNearWorker(
        workerLocation: const LocationPoint(lat: 31.52, lng: 74.36),
        radiusKm: 10,
        categoryIds: [],
      );

      expect(nearby, isEmpty);
    });
  });

  group('getPublicProfile', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('returns self worker profile', () {
      final result = appState.getPublicProfile(appState.workerProfile!.id);
      expect(result, isNotNull);
      expect(result!.profile.displayName, 'Test Worker');
      expect(result.workerDetails, isNotNull);
    });

    test('returns self employer profile', () {
      final result = appState.getPublicProfile(appState.employerProfile!.id);
      expect(result, isNotNull);
      expect(result!.profile.displayName, 'Test Employer');
      expect(result.workerDetails, isNull);
    });

    test('returns null for unknown profile', () {
      expect(appState.getPublicProfile('unknown-id'), isNull);
    });
  });

  group('Sanitization', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('addJob strips HTML from title and description', () {
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: '<script>alert("xss")</script>Clean Title',
        description: '<b>Safe</b> description',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
        urgency: JobUrgency.today,
      );

      expect(appState.jobs.first.title, contains('Clean Title'));
      expect(appState.jobs.first.title, isNot(contains('<script>')));
      expect(appState.jobs.first.description, isNot(contains('<b>')));
    });

    test('sendMessage strips HTML from content', () {
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      final conv = appState.getOrCreateConversation('job-test', appState.workerProfile!.id);
      appState.sendMessage(conv.id, '<a href="bad">click me</a>Hello');

      expect(appState.messages.last.content, 'click meHello');
      expect(appState.messages.last.content, isNot(contains('<a')));
    });
  });

  group('Conversation operations', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('getOrCreateConversation creates new conversation', () {
      final conv = appState.getOrCreateConversation('job-1', appState.workerProfile!.id);
      expect(conv.jobId, 'job-1');
      expect(conv.workerProfileId, appState.workerProfile!.id);
      expect(appState.conversations.length, 1);
    });

    test('getOrCreateConversation returns existing conversation', () {
      final conv1 = appState.getOrCreateConversation('job-1', appState.workerProfile!.id);
      final conv2 = appState.getOrCreateConversation('job-1', appState.workerProfile!.id);
      expect(conv1.id, conv2.id);
      expect(appState.conversations.length, 1);
    });

    test('sendMessage adds multiple messages in order', () {
      final conv = appState.getOrCreateConversation('job-1', appState.workerProfile!.id);
      appState.sendMessage(conv.id, 'First');
      appState.sendMessage(conv.id, 'Second');

      expect(appState.messages.length, 2);
      expect(appState.messages[0].content, 'First');
      expect(appState.messages[1].content, 'Second');
    });
  });

  group('Worker details', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Initial bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('updateWorkerBio updates the bio', () {
      appState.updateWorkerBio('New bio text');
      expect(appState.workerDetails!.bio, 'New bio text');

      appState.updateWorkerBio('Updated again');
      expect(appState.workerDetails!.bio, 'Updated again');
    });

    test('updateWorkerBio strips HTML', () {
      appState.updateWorkerBio('<script>alert(1)</script>Safe bio');
      expect(appState.workerDetails!.bio, 'alert(1)Safe bio');
      expect(appState.workerDetails!.bio, isNot(contains('<script>')));
    });
  });

  group('Hire with reject', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
      appState.completeWorkerOnboarding(
        displayName: 'Test Worker',
        categoryIds: ['home-electrical'],
        bio: 'Test bio',
        yearsExperience: 5,
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('hireWorker updates application to hired', () {
      final pinLoc = const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test');
      appState.addJob(
        employerProfileId: appState.employerProfile!.id,
        categoryId: 'home-test',
        title: 'Test Job',
        description: 'Test',
        budgetAmount: 1000,
        budgetType: BudgetType.fixed,
        pinLocation: pinLoc,
        urgency: JobUrgency.today,
      );
      final jobId = appState.jobs.first.id;
      final workerId = appState.workerProfile!.id;

      appState.expressInterest(jobId);
      appState.hireWorker(jobId, workerId);

      final hiredApps = appState.applications.where((a) => a.status == ApplicationStatus.hired).toList();
      expect(hiredApps.length, 1);
      expect(hiredApps.first.workerProfileId, workerId);

      final hiredJob = appState.jobs.firstWhere((j) => j.id == jobId);
      expect(hiredJob.status, JobStatus.hired);
      expect(hiredJob.hiredWorkerProfileId, workerId);
    });
  });

  group('Conversation dedup (failure-mode)', () {
    setUp(() async {
      appState = AppState();
      await appState.initialize();
      appState.loginWithPhoneOrEmail('test@rozgar.pk');
      appState.completeEmployerOnboarding(
        displayName: 'Test Employer',
        homeLocation: const LocationPoint(lat: 31.52, lng: 74.36, address: 'Test'),
      );
    });

    tearDown(() {
      appState.dispose();
    });

    test('getOrCreateConversation returns same instance for same job+worker', () {
      final conv1 = appState.getOrCreateConversation('job-dedup', 'wrk-1');
      final conv2 = appState.getOrCreateConversation('job-dedup', 'wrk-1');
      expect(identical(conv1, conv2), true);
    });

    test('getOrCreateConversation creates distinct convs for different workers', () {
      final conv1 = appState.getOrCreateConversation('job-dedup', 'wrk-1');
      final conv2 = appState.getOrCreateConversation('job-dedup', 'wrk-2');
      expect(conv1.id, isNot(equals(conv2.id)));
    });

    test('no duplicate conversations in list after multiple calls', () {
      appState.getOrCreateConversation('job-dedup', 'wrk-1');
      appState.getOrCreateConversation('job-dedup', 'wrk-1');
      appState.getOrCreateConversation('job-dedup', 'wrk-1');
      final matching = appState.conversations
          .where((c) => c.jobId == 'job-dedup' && c.workerProfileId == 'wrk-1');
      expect(matching.length, 1);
    });
  });
}
