import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_identity.dart';
import '../models/profile.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/conversation.dart';
import '../models/review.dart';
import '../models/notification_item.dart';
import '../models/location_point.dart';
import '../services/supabase_service.dart';
import '../services/supabase_config.dart';
import '../utils/geo.dart';
import '../utils/translations.dart';

// ========== WORKER ENTRY ==========

// ========== WORKER ENTRY ==========

class WorkerEntry {
  final Profile profile;
  final WorkerDetails details;
  const WorkerEntry({required this.profile, required this.details});
}

// ========== APP STATE ==========

/// Application state. Keeps an in-memory cache for fast synchronous reads
/// by the UI, while persisting all mutations to Supabase asynchronously.
///
/// During initialization, data is loaded from Supabase. The app requires
/// a valid Supabase session to function.
class AppState extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  bool _isSupabaseAvailable = true;

  // Auth & Profiles
  AuthIdentity? _authIdentity;
  Profile? _employerProfile;
  Profile? _workerProfile;
  WorkerDetails? _workerDetails;
  String? _activeProfileId;
  LanguageOption _language = LanguageOption.en;

  /// True when authenticated but no profiles exist yet (new sign-up via email confirmation).
  bool _needsOnboarding = false;

  // Jobs
  List<Job> _jobs = [];

  // Applications
  List<Application> _applications = [];

  // Conversations & Messages
  List<Conversation> _conversations = [];
  List<Message> _messages = [];

  // Reviews
  List<Review> _reviews = [];

  // Notifications
  List<NotificationItem> _notifications = [];

  // Cached workers from Supabase
  List<WorkerEntry> _cachedWorkers = [];

  // Realtime channels
  final List<RealtimeChannel> _messageChannels = [];
  final Set<String> _subscribedConversationIds = {};
  RealtimeChannel? _notificationChannel;

  // ===== INITIALIZATION =====

  /// Load all data from Supabase for the current session.
  Future<void> initialize() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) {
        _isSupabaseAvailable = false;
        notifyListeners();
        return;
      }

      _authIdentity = AuthIdentity(
        id: session.user.id,
        phoneNumber: session.user.phone,
        email: session.user.email,
        preferredLanguage: _language == LanguageOption.ur
            ? PreferredLanguage.ur
            : PreferredLanguage.en,
        createdAt: (session.user.createdAt is DateTime
              ? session.user.createdAt as DateTime
              : DateTime.tryParse(session.user.createdAt.toString()) ?? DateTime.now()),
      );

      // Load ALL profiles for this auth user (both employer and worker)
      final profiles = await _supabase.getProfilesByAuthId(session.user.id);
      for (final profile in profiles) {
        if (profile.profileType == ProfileType.employer) {
          _employerProfile = profile;
        } else if (profile.profileType == ProfileType.worker) {
          _workerProfile = profile;
          _workerDetails = await _supabase.getWorkerDetails(profile.id);
        }
      }

      // No profiles yet — needs onboarding
      if (_employerProfile == null && _workerProfile == null) {
        _needsOnboarding = true;
      }

      // Set active profile
      if (_employerProfile != null) {
        _activeProfileId = _employerProfile!.id;
      } else if (_workerProfile != null) {
        _activeProfileId = _workerProfile!.id;
      }

      // Load jobs
      _jobs = await _supabase.getAllJobs();

      // Load applications for all jobs
      final allJobIds = _jobs.map((j) => j.id).toSet();
      _applications = [];
      for (final jobId in allJobIds) {
        final jobApps = await _supabase.getApplicationsForJob(jobId);
        _applications.addAll(jobApps);
      }

      // Load conversations for the active profile
      if (_activeProfileId != null) {
        _conversations = await _supabase.getConversations(_activeProfileId!);

        // Load messages for ALL conversations
        _messages = [];
        for (final conv in _conversations) {
          final convMessages = await _supabase.getMessages(conv.id);
          _messages.addAll(convMessages);
        }
      }

      // Load notifications
      if (_activeProfileId != null) {
        _notifications = await _supabase.getNotifications(_activeProfileId!);
      }

      // Load all workers from Supabase
      await _loadAllWorkersFromSupabase();

      // Set up realtime subscriptions
      _setupSubscriptions();

      _isSupabaseAvailable = true;
    } catch (e) {
      debugPrint('Supabase init error: $e');
      _isSupabaseAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _loadAllWorkersFromSupabase() async {
    try {
      final workers = await _supabase.getAllWorkers();
      _cachedWorkers = workers
          .map((w) => WorkerEntry(profile: w.profile, details: w.details))
          .toList();
    } catch (e) {
      debugPrint('Failed to load workers from Supabase: $e');
    }
  }

  void _setupSubscriptions() {
    // Clear any existing subscriptions first (prevents leaks on re-initialize)
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    _subscribedConversationIds.clear();
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;

    // Subscribe to all conversation messages for live chat updates
    if (_activeProfileId != null) {
      // Subscribe to all conversations for realtime messages
      for (final conv in _conversations) {
        _subscribeToConversation(conv.id);
      }
    }

    // Subscribe to notifications
    if (_activeProfileId != null) {
      _notificationChannel = _supabase.subscribeToNotifications(
        _activeProfileId!,
        (notification) {
          _notifications = [notification, ..._notifications];
          notifyListeners();
        },
      );
    }
  }

  /// Subscribe to realtime messages for a single conversation.
  /// Call this when a new conversation is created at runtime.
  void _subscribeToConversation(String conversationId) {
    // Avoid duplicate subscriptions
    if (!_subscribedConversationIds.add(conversationId)) return;
    final channel = _supabase.subscribeToMessages(
      conversationId,
      (message) {
        _messages = [..._messages, message];
        _conversations = _conversations.map((c) {
          if (c.id == message.conversationId) {
            return c.copyWith(
              lastMessageText: message.content,
              lastMessageTime: message.sentAt,
            );
          }
          return c;
        }).toList();
        notifyListeners();
      },
    );
    _messageChannels.add(channel);
  }

  @override
  void dispose() {
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    _subscribedConversationIds.clear();
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  // ===== GETTERS =====

  bool get isSupabaseAvailable => _isSupabaseAvailable;
  bool get needsOnboarding => _needsOnboarding;
  AuthIdentity? get authIdentity => _authIdentity;
  Profile? get employerProfile => _employerProfile;
  Profile? get workerProfile => _workerProfile;
  WorkerDetails? get workerDetails => _workerDetails;
  String? get activeProfileId => _activeProfileId;

  Profile? get activeProfile {
    if (_activeProfileId == _employerProfile?.id) return _employerProfile;
    if (_activeProfileId == _workerProfile?.id) return _workerProfile;
    return _employerProfile;
  }

  ProfileType get activeProfileType =>
      activeProfile?.profileType ?? ProfileType.employer;
  LanguageOption get language => _language;
  List<Job> get jobs => List.unmodifiable(_jobs);
  List<Application> get applications => List.unmodifiable(_applications);
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<Message> get messages => List.unmodifiable(_messages);
  List<Review> get reviews => List.unmodifiable(_reviews);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  List<WorkerEntry> get allWorkers {
    final workers = <WorkerEntry>[];
    if (_workerProfile != null && _workerDetails != null) {
      workers.add(WorkerEntry(
          profile: _workerProfile!, details: _workerDetails!));
    }
    workers.addAll(_cachedWorkers);
    return workers;
  }

  // ===== ACTIONS (sync helpers) =====

  void setLanguage(LanguageOption lang) {
    _language = lang;
    notifyListeners();
  }

  void switchProfile(ProfileType type) {
    if (type == ProfileType.employer && _employerProfile != null) {
      _activeProfileId = _employerProfile!.id;
    } else if (type == ProfileType.worker && _workerProfile != null) {
      _activeProfileId = _workerProfile!.id;
    }
    notifyListeners();
  }

  /// Sign in with email and password via Supabase.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.signInWithEmail(email, password);
      if (response.session != null) {
        _authIdentity = AuthIdentity(
          id: response.session!.user.id,
          email: email,
          phoneNumber: response.session!.user.phone,
          preferredLanguage: _language == LanguageOption.ur
              ? PreferredLanguage.ur
              : PreferredLanguage.en,
          createdAt: DateTime.now(),
        );
        // Reload data from Supabase
        await initialize();
        return null; // no error
      }
      return 'Login failed. Please check your credentials.';
    } catch (e) {
      debugPrint('Sign in error: $e');
      return 'Login failed: ${e.toString()}';
    }
  }

  /// Sign up with email and password via Supabase.
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.signUpWithEmail(email, password);
      if (response.session != null) {
        _authIdentity = AuthIdentity(
          id: response.session!.user.id,
          email: email,
          preferredLanguage: _language == LanguageOption.ur
              ? PreferredLanguage.ur
              : PreferredLanguage.en,
          createdAt: DateTime.now(),
        );
        await initialize();
        return null;
      }
      return 'Signup successful! Check your email to confirm your account.';
    } catch (e) {
      debugPrint('Sign up error: $e');
      return 'Signup failed: ${e.toString()}';
    }
  }

  /// Send a password reset email to [email].
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.resetPasswordForEmail(email);
      return null; // no error
    } catch (e) {
      debugPrint('Password reset error: $e');
      return 'Failed to send reset email: ${e.toString()}';
    }
  }

  /// Legacy login method (used by the existing OTP flow).
  void loginWithPhoneOrEmail(String contact) {
    final isPhone = contact.contains('+') ||
        contact.replaceAll(' ', '').contains(RegExp(r'^\d+$'));
    _authIdentity = AuthIdentity(
      id: 'auth-user-1',
      phoneNumber: isPhone ? contact : null,
      email: !isPhone ? contact : null,
      preferredLanguage: _language == LanguageOption.ur
          ? PreferredLanguage.ur
          : PreferredLanguage.en,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  bool verifyOtp(String otp) {
    return true;
  }

  Future<void> logout() async {
    // Wrap signOut in try/catch in case Supabase isn't available
    if (_isSupabaseAvailable) {
      try {
        await _supabase.signOut();
      } catch (_) {
        // Ignore errors during sign out
      }
    }
    _authIdentity = null;
    _employerProfile = null;
    _workerProfile = null;
    _workerDetails = null;
    _activeProfileId = null;
    _jobs = [];
    _applications = [];
    _conversations = [];
    _messages = [];
    _reviews = [];
    _notifications = [];
    _cachedWorkers = [];
    for (final ch in _messageChannels) {
      ch.unsubscribe();
    }
    _messageChannels.clear();
    _subscribedConversationIds.clear();
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
    _isSupabaseAvailable = false;
    notifyListeners();
  }

  void completeWorkerOnboarding({
    required String displayName,
    required List<String> categoryIds,
    required String bio,
    required int yearsExperience,
    required LocationPoint homeLocation,
  }) {
    final authId = _authIdentity?.id;
    if (authId == null) return;
    _workerProfile = Profile(
      id: 'wrk-$authId',
      authIdentityId: authId,
      profileType: ProfileType.worker,
      displayName: displayName,
      profilePhotoUrl: '',
      city: (homeLocation.city != null && homeLocation.city!.isNotEmpty) ? homeLocation.city! : 'Lahore',
      homeLocation: homeLocation,
      createdAt: DateTime.now(),
      isVerified: true,
      idVerificationStatus: IdVerificationStatus.verified,
      accountStatus: AccountStatus.active,
      onboardingCompletionPct: 90,
    );
    _workerDetails = WorkerDetails(
      profileId: _workerProfile!.id,
      categoryIds: categoryIds,
      bio: bio,
      yearsExperience: yearsExperience,
      rateNote: '',
      availabilityStatus: AvailabilityStatus.today,
      notificationRadiusKm: 15,
      isOnlineForMap: true,
      currentLocation: homeLocation,
      averageRating: 0.0,
      totalJobsCompleted: 0,
      responseTimeAvgMinutes: 0,
    );
    _activeProfileId = _workerProfile!.id;
    _needsOnboarding = false;
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.createProfile(_workerProfile!);
      _supabase.createWorkerDetails(_workerDetails!);
    }
  }

  void completeEmployerOnboarding({
    required String displayName,
    required LocationPoint homeLocation,
  }) {
    final authId = _authIdentity?.id;
    if (authId == null) return;
    _employerProfile = Profile(
      id: authId,
      authIdentityId: authId,
      profileType: ProfileType.employer,
      displayName: displayName,
      profilePhotoUrl: '',
      city: (homeLocation.city != null && homeLocation.city!.isNotEmpty) ? homeLocation.city! : 'Lahore',
      homeLocation: homeLocation,
      createdAt: DateTime.now(),
      isVerified: true,
      idVerificationStatus: IdVerificationStatus.verified,
      accountStatus: AccountStatus.active,
      onboardingCompletionPct: 100,
    );
    _activeProfileId = _employerProfile!.id;
    _needsOnboarding = false;
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.createProfile(_employerProfile!);
    }
  }

  Job addJob({
    required String employerProfileId,
    required String categoryId,
    required String title,
    required String description,
    AIExtractedSummary? aiExtractedSummary,
    required double budgetAmount,
    required BudgetType budgetType,
    required LocationPoint pinLocation,
    required JobUrgency urgency,
  }) {
    final jobId = 'job-${DateTime.now().millisecondsSinceEpoch}';
    final job = Job(
      id: jobId,
      employerProfileId: employerProfileId,
      categoryId: categoryId,
      title: title,
      description: description,
      aiExtractedSummary: aiExtractedSummary,
      budgetAmount: budgetAmount,
      budgetType: budgetType,
      pinLocation: pinLocation,
      status: JobStatus.open,
      urgency: urgency,
      createdAt: DateTime.now(),
    );
    _jobs.insert(0, job);
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.createJob(job);
      // Notify nearby workers
      for (final worker in _cachedWorkers) {
        final dist = calculateDistanceKm(
          lat1: job.pinLocation.lat, lng1: job.pinLocation.lng,
          lat2: worker.details.currentLocation.lat, lng2: worker.details.currentLocation.lng,
        );
        if (dist <= worker.details.notificationRadiusKm) {
          _supabase.createNotification(NotificationItem(
            id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
            profileId: worker.profile.id,
            type: NotificationType.newJobRadius,
            titleEn: 'New Job Available Near You!',
            titleUr: 'آپ کے قریب نیا کام دستیاب ہے!',
            bodyEn: 'A $title job is ${dist.toStringAsFixed(1)} km from your location.',
            bodyUr: '$title کا کام آپ سے صرف ${dist.toStringAsFixed(1)} کلومیٹر دور ہے۔',
            isRead: false,
            createdAt: DateTime.now(),
            payload: {'jobId': job.id},
          ));
        }
      }
    }

    return job;
  }

  List<Job> getJobsNearWorker({
    required LocationPoint workerLocation,
    required double radiusKm,
    required List<String> categoryIds,
  }) {
    return _jobs.where((job) {
      if (job.status != JobStatus.open) return false;
      final dist = calculateDistanceKm(
        lat1: job.pinLocation.lat,
        lng1: job.pinLocation.lng,
        lat2: workerLocation.lat,
        lng2: workerLocation.lng,
      );
      if (dist > radiusKm) return false;
      if (categoryIds.isEmpty) return true;
      return categoryIds.any(
          (cat) => job.categoryId.contains(cat) || cat.contains(job.categoryId));
    }).toList();
  }

  List<Job> getEmployerJobs() {
    if (_employerProfile == null) return [];
    return _jobs
        .where((j) => j.employerProfileId == _employerProfile!.id)
        .toList();
  }

  void expressInterest(String jobId, {String? message}) {
    if (_workerProfile == null) return;

    final app = Application(
      id: 'app-${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      workerProfileId: _workerProfile!.id,
      status: ApplicationStatus.interested,
      appliedAt: DateTime.now(),
      message: message ??
          'Assalam-o-Alaikum! I am available to start work immediately.',
      aiMatchNote: '⚡ Verified candidate, top rated in category nearby.',
    );
    _applications.add(app);

    final job = _jobs.where((j) => j.id == jobId).firstOrNull;
    if (job != null) {
      // Notify the employer
      final notif = NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        profileId: job.employerProfileId,
        type: NotificationType.workerInterested,
        titleEn: 'Worker Interested in your Job',
        titleUr: 'کاریگر نے آپ کے کام میں دلچسپی ظاہر کی',
        bodyEn:
            '${_workerProfile!.displayName} expressed interest in "${job.title}".',
        bodyUr:
            '${_workerProfile!.displayName} نے آپ کے کام میں دلچسپی ظاہر کی ہے۔',
        isRead: false,
        createdAt: DateTime.now(),
        payload: {'jobId': jobId},
      );
      _notifications.insert(0, notif);

      if (_isSupabaseAvailable) {
        _supabase.createNotification(notif);
      }
    }
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.createApplication(app);
    }
  }

  void hireWorker(String jobId, String workerProfileId) {
    // Collect IDs of apps to reject
    final rejectAppIds = _applications
        .where((a) => a.jobId == jobId && a.workerProfileId != workerProfileId)
        .map((a) => a.id)
        .toList();

    _jobs = _jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(
          status: JobStatus.hired,
          hiredWorkerProfileId: workerProfileId,
        );
      }
      return j;
    }).toList();

    _applications = _applications.map((a) {
      if (a.jobId == jobId) {
        if (a.workerProfileId == workerProfileId) {
          return a.copyWith(status: ApplicationStatus.hired);
        }
        return a.copyWith(status: ApplicationStatus.rejected);
      }
      return a;
    }).toList();

    final job = _jobs.where((j) => j.id == jobId).firstOrNull;
    if (job != null) {
      // Create conversation in Supabase
      _createConversationInSupabase(jobId, workerProfileId);
      
      final notif = NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        profileId: workerProfileId,
        type: NotificationType.jobHired,
        titleEn: 'You are Hired!',
        titleUr: 'مبارک ہو! آپ کا انتخاب ہو گیا ہے',
        bodyEn: 'You were hired for "${job.title}". Tap to open chat.',
        bodyUr: 'آپ کو "${job.title}" کے لیے منتخب کر لیا گیا ہے۔',
        isRead: false,
        createdAt: DateTime.now(),
        payload: {'jobId': jobId},
      );
      _notifications.insert(0, notif);

      if (_isSupabaseAvailable) {
        _supabase.createNotification(notif);
      }
    }
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.updateJobStatus(jobId,
          status: 'hired', hiredWorkerProfileId: workerProfileId);
      // Reject other applicants in Supabase
      if (rejectAppIds.isNotEmpty) {
        _supabase.hireAndReject(
          jobId: jobId,
          hiredWorkerProfileId: workerProfileId,
          rejectApplicationIds: rejectAppIds,
        );
      }
    }
  }

  Future<void> _createConversationInSupabase(String jobId, String workerProfileId) async {
    if (!_isSupabaseAvailable || _employerProfile == null) return;
    try {
      final conv = await _supabase.getOrCreateConversation(
        jobId: jobId,
        employerProfileId: _employerProfile!.id,
        workerProfileId: workerProfileId,
      );
      // Update local cache
      final existing = _conversations.indexWhere((c) => c.id == conv.id);
      if (existing == -1) {
        _conversations.insert(0, conv);
        // Subscribe to realtime messages for the new conversation
        _subscribeToConversation(conv.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to create conversation: $e');
    }
  }

  void completeJob(String jobId) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId) return j.copyWith(status: JobStatus.completed);
      return j;
    }).toList();
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.updateJobStatus(jobId, status: 'completed');
    }
  }

  Conversation getOrCreateConversation(String jobId, String workerProfileId) {
    final existing = _conversations.where((c) =>
        c.jobId == jobId && c.workerProfileId == workerProfileId).firstOrNull;
    if (existing != null) return existing;

    final conv = Conversation(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      employerProfileId: _employerProfile?.id ?? '',
      workerProfileId: workerProfileId,
      lastMessageText: 'Conversation started',
      lastMessageTime: DateTime.now(),
    );
    _conversations.insert(0, conv);
    notifyListeners();

    // Also create in Supabase if available
    if (_isSupabaseAvailable) {
      _createConversationInSupabase(jobId, workerProfileId);
    }
    return conv;
  }

  void sendMessage(
    String conversationId,
    String content, {
    ContentType contentType = ContentType.text,
    String? mediaUrl,
  }) {
    if (activeProfile == null) return;

    final msg = Message(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderProfileId: activeProfile!.id,
      contentType: contentType,
      content: content,
      mediaUrl: mediaUrl,
      sentAt: DateTime.now(),
    );
    _messages.add(msg);

    _conversations = _conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(
          lastMessageText: content,
          lastMessageTime: msg.sentAt,
        );
      }
      return c;
    }).toList();
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.sendMessage(msg);
      // Sync conversation's last message to Supabase so other users see it
      _supabase.updateConversationLastMessage(
        conversationId,
        lastMessageText: content,
        lastMessageTime: msg.sentAt,
      );
    }
  }

  void addReview(
      String jobId, String revieweeProfileId, int rating, String comment) {
    if (activeProfile == null) return;
    final review = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      reviewerProfileId: activeProfile!.id,
      revieweeProfileId: revieweeProfileId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.insert(0, review);
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.createReview(review);
    }
  }

  void toggleWorkerOnline(bool online) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(isOnlineForMap: online);
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.updateWorkerDetails(
        _workerDetails!.profileId,
        {'is_online_for_map': online},
      );
    }
  }

  void updateWorkerRadius(double radiusKm) {
    if (_workerDetails == null) return;
    _workerDetails =
        _workerDetails!.copyWith(notificationRadiusKm: radiusKm);
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.updateWorkerDetails(
        _workerDetails!.profileId,
        {'notification_radius_km': radiusKm},
      );
    }
  }

  void updateWorkerBio(String bio) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(bio: bio);
    notifyListeners();

    if (_isSupabaseAvailable) {
      _supabase.updateWorkerDetails(
        _workerDetails!.profileId,
        {'bio': bio},
      );
    }
  }

  /// Trigger a UI refresh (used by pull-to-refresh on employer/worker home).
  void refresh() {
    notifyListeners();
  }

  void markNotificationsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    if (_isSupabaseAvailable && _activeProfileId != null) {
      _supabase.markNotificationsRead(_activeProfileId!);
    }
  }

  ({Profile profile, WorkerDetails? workerDetails, List<Review> reviews})?
      getPublicProfile(String profileId) {
    // Check worker profile
    if (profileId == _workerProfile?.id) {
      return (
        profile: _workerProfile!,
        workerDetails: _workerDetails,
        reviews: _reviews,
      );
    }
    // Check employer profile
    if (profileId == _employerProfile?.id) {
      return (
        profile: _employerProfile!,
        workerDetails: null,
        reviews: _reviews,
      );
    }
    // Check cached workers from Supabase
    final cached = _cachedWorkers
        .where((w) => w.profile.id == profileId)
        .firstOrNull;
    if (cached != null) {
      return (
        profile: cached.profile,
        workerDetails: cached.details,
        reviews: _reviews,
      );
    }
    return null;
  }
}
