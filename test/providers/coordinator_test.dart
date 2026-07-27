import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/coordinator.dart';
import 'package:rozgar/providers/auth_provider.dart';
import 'package:rozgar/providers/profile_provider.dart';
import 'package:rozgar/providers/job_provider.dart';
import 'package:rozgar/providers/chat_provider.dart';
import 'package:rozgar/providers/notification_provider.dart';
import 'package:rozgar/providers/worker_provider.dart';
import 'package:rozgar/providers/settings_provider.dart';
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

  group('Initial state', () {
    test('isSupabaseAvailable defaults to true', () {
      expect(coordinator.isSupabaseAvailable, true);
    });

    test('lastOperationError defaults to null', () {
      expect(coordinator.lastOperationError, isNull);
    });

    test('holds references to all 7 notifiers', () {
      expect(coordinator.auth, same(auth));
      expect(coordinator.profile, same(profile));
      expect(coordinator.jobs, same(jobs));
      expect(coordinator.chat, same(chat));
      expect(coordinator.notifications, same(notifications));
      expect(coordinator.workers, same(workers));
      expect(coordinator.settings, same(settings));
    });
  });

  group('clearOperationError', () {
    test('clears error and notifies listeners', () {
      var notified = false;
      coordinator.addListener(() => notified = true);
      coordinator.clearOperationError();
      expect(coordinator.lastOperationError, isNull);
      expect(notified, true);
    });
  });

  group('initialize without Supabase', () {
    test('sets isSupabaseAvailable to false when Supabase not initialized',
        () async {
      await coordinator.initialize();
      expect(coordinator.isSupabaseAvailable, false);
    });

    test('sets lastOperationError on failure', () async {
      await coordinator.initialize();
      expect(coordinator.lastOperationError, isNotNull);
    });
  });

  group('logout', () {
    test('clears all domain notifiers', () async {
      // Set some state first
      settings.setLanguage(LanguageOption.ur);
      expect(settings.language, LanguageOption.ur);

      await coordinator.logout();

      // Settings should be reset
      expect(settings.language, LanguageOption.en);
      // Jobs should be empty
      expect(jobs.jobs, isEmpty);
      expect(jobs.applications, isEmpty);
      // Chat should be empty
      expect(chat.conversations, isEmpty);
      expect(chat.messages, isEmpty);
      // Notifications should be empty
      expect(notifications.notifications, isEmpty);
      // Workers should be empty
      expect(workers.allWorkers, isEmpty);
    });

    test('notifies listeners after logout', () async {
      var notified = false;
      coordinator.addListener(() => notified = true);
      await coordinator.logout();
      expect(notified, true);
    });
  });

  group('refreshFromSupabase without Supabase', () {
    test('falls back to notifyListeners when Supabase unavailable', () async {
      // First make Supabase unavailable
      await coordinator.initialize();
      expect(coordinator.isSupabaseAvailable, false);

      var notified = false;
      coordinator.addListener(() => notified = true);
      await coordinator.refreshFromSupabase();
      expect(notified, true);
    });
  });
}
