import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/application.dart';
import '../models/conversation.dart';
import '../services/supabase_service.dart';
import '../services/supabase_config.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'job_provider.dart';
import 'chat_provider.dart';
import 'notification_provider.dart';
import 'worker_provider.dart';
import 'settings_provider.dart';

/// Thin orchestration layer that coordinates cross-domain operations
/// across the 7 domain notifiers. Replaces AppState's cross-cutting methods.
///
/// This is the Strangler Fig migration target: screens will eventually
/// call Coordinator methods instead of AppState methods, then AppState
/// can be deleted.
class Coordinator extends ChangeNotifier {
  final AuthNotifier auth;
  final ProfileNotifier profile;
  final JobNotifier jobs;
  final ChatNotifier chat;
  final NotificationNotifier notifications;
  final WorkerNotifier workers;
  final SettingsNotifier settings;
  final SupabaseService _supabase;

  bool _isSupabaseAvailable = true;
  String? _lastOperationError;

  Coordinator({
    required this.auth,
    required this.profile,
    required this.jobs,
    required this.chat,
    required this.notifications,
    required this.workers,
    required this.settings,
    SupabaseService? supabase,
  }) : _supabase = supabase ?? SupabaseService.instance;

  bool get isSupabaseAvailable => _isSupabaseAvailable;
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Load all data from Supabase for the current session.
  /// Mirrors AppState.initialize() but distributes state to domain notifiers.
  Future<void> initialize() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) {
        _isSupabaseAvailable = false;
        notifyListeners();
        return;
      }

      _isSupabaseAvailable = true;

      // Load profiles
      final profiles = await _supabase.getProfilesByAuthId(session.user.id);
      WorkerDetails? workerDetails;
      for (final p in profiles) {
        if (p.profileType == ProfileType.worker) {
          workerDetails = await _supabase.getWorkerDetails(p.id);
        }
      }
      profile.setProfiles(profiles, workerDetails);

      final activeProfileId = profile.activeProfileId;

      // Load jobs
      final allJobs = await _supabase.getAllJobs();
      jobs.setJobs(allJobs);

      // Load applications for all jobs
      final allJobIds = allJobs.map((j) => j.id).toSet();
      final allApplications = <Application>[];
      for (final jobId in allJobIds) {
        final jobApps = await _supabase.getApplicationsForJob(jobId);
        allApplications.addAll(jobApps);
      }
      jobs.setApplications(allApplications);

      // Load conversations and messages
      if (activeProfileId != null) {
        final conversations = await _supabase.getConversations(activeProfileId);
        chat.setConversations(conversations);

        final allMessages = <Message>[];
        for (final conv in conversations) {
          final convMessages = await _supabase.getMessages(conv.id);
          allMessages.addAll(convMessages);
        }
        chat.setMessages(allMessages);

        // Subscribe to realtime
        chat.subscribeToAllConversations(conversations);
        notifications.subscribe(activeProfileId);
      }

      // Load notifications
      if (activeProfileId != null) {
        final notifs = await _supabase.getNotifications(activeProfileId);
        notifications.setNotifications(notifs);
      }

      // Load all workers
      await workers.loadAllWorkers();

      _isSupabaseAvailable = true;
    } catch (e) {
      debugPrint('Coordinator init error: $e');
      _isSupabaseAvailable = false;
      _lastOperationError = 'Failed to initialize: ${e.toString()}';
    }
    notifyListeners();
  }

  // ===========================================================================
  // CROSS-DOMAIN OPERATIONS
  // ===========================================================================

  /// Hire a worker for a job. Coordinates JobNotifier, ChatNotifier,
  /// and NotificationNotifier.
  void hireWorker({
    required String jobId,
    required String workerProfileId,
    required String employerProfileId,
  }) {
    jobs.hireWorker(
      jobId,
      workerProfileId,
      employerProfileId,
      onConversationCreated: (conv) {
        chat.setConversations([...chat.conversations, conv]);
        chat.subscribeToConversation(conv.id);
      },
    );
  }

  /// Refresh all data from Supabase (real pull-to-refresh).
  Future<void> refreshFromSupabase() async {
    final activeProfileId = profile.activeProfileId;
    if (!_isSupabaseAvailable || activeProfileId == null) {
      notifyListeners();
      return;
    }
    try {
      final isEmployer = profile.activeProfileType == ProfileType.employer;

      if (isEmployer) {
        final employerJobs = await _supabase.getEmployerJobs(activeProfileId);
        jobs.setJobs(employerJobs);
        final allJobIds = employerJobs.map((j) => j.id).toSet();
        final allApplications = <Application>[];
        for (final jobId in allJobIds) {
          final jobApps = await _supabase.getApplicationsForJob(jobId);
          allApplications.addAll(jobApps);
        }
        jobs.setApplications(allApplications);
      } else {
        final allJobs = await _supabase.getAllJobs();
        jobs.setJobs(allJobs);
        final workerApps =
            await _supabase.getApplicationsForWorker(activeProfileId);
        jobs.setApplications(workerApps);
      }

      final conversations = await _supabase.getConversations(activeProfileId);
      chat.setConversations(conversations);

      final notifs = await _supabase.getNotifications(activeProfileId);
      notifications.setNotifications(notifs);

      await workers.loadAllWorkers();
      notifyListeners();
    } catch (e) {
      debugPrint('Coordinator refresh failed: $e');
      _lastOperationError = 'Refresh failed';
      notifyListeners();
    }
  }

  /// Logout and clear all domain state.
  Future<void> logout() async {
    await auth.logout();
    profile.clear();
    jobs.clear();
    chat.clear();
    notifications.clear();
    workers.clear();
    settings.clear();
    notifyListeners();
  }
}
