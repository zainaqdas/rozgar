import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/conversation.dart';
import '../models/review.dart';
import '../models/notification_item.dart';
import '../models/location_point.dart';
import '../models/favorite.dart';
import '../models/report.dart';
import '../models/nearby_worker.dart';
import 'supabase_config.dart';
import '../utils/geo.dart';

/// Centralized service for all Supabase CRUD operations.
///
/// All models already use snake_case keys in toJson()/fromJson(),
/// so data passes through directly — no key conversion needed.
///
/// Location points are stored as JSONB; distance filtering is done
/// client-side with the Haversine formula (can switch to PostGIS
/// ST_DWithin later).
class SupabaseService {
  @visibleForTesting
  SupabaseService.test();

  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  @visibleForTesting
  SupabaseClient? testClient;

  SupabaseClient get _client => testClient ?? SupabaseConfig.client;

  // ===========================================================================
  // AUTH
  // ===========================================================================

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Send a password reset email.
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send an OTP to a phone number via SMS.
  Future<void> signInWithPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  /// Verify an SMS OTP and return the auth session.
  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Listen to auth state changes.
  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  /// Get the current Supabase user ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  // ===========================================================================
  // PROFILES
  // ===========================================================================

  /// Fetch a single profile by [id].
  Future<Profile?> getProfile(String id) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Fetch the first profile associated with the current auth user.
  /// Uses limit(1) instead of maybeSingle() because dual-profile users
  /// (employer + worker) legitimately have 2 rows.
  Future<Profile?> getProfileByAuthId(String authId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('auth_identity_id', authId)
        .limit(1);
    if (response.isEmpty) return null;
    return Profile.fromJson(response.first);
  }

  /// Fetch ALL profiles for a given auth identity (employer + worker).
  Future<List<Profile>> getProfilesByAuthId(String authId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('auth_identity_id', authId);
    return response.map((p) => Profile.fromJson(p)).toList();
  }

  /// Create or update a profile (upsert to handle retry on 409).
  Future<Profile> createProfile(Profile profile) async {
    final response = await _client
        .from('profiles')
        .upsert(profile.toJson())
        .select()
        .single();
    return Profile.fromJson(response);
  }

  /// Update an existing profile.
  Future<Profile> updateProfile(String id, Map<String, dynamic> updates) async {
    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromJson(response);
  }

  /// Fetch worker details for a given profile.
  Future<WorkerDetails?> getWorkerDetails(String profileId) async {
    final response = await _client
        .from('worker_details')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (response == null) return null;
    return WorkerDetails.fromJson(response);
  }

  /// Create worker details.
  Future<WorkerDetails> createWorkerDetails(WorkerDetails details) async {
    final response = await _client
        .from('worker_details')
        .insert(details.toJson())
        .select()
        .single();
    return WorkerDetails.fromJson(response);
  }

  /// Update worker details.
  Future<WorkerDetails> updateWorkerDetails(
      String profileId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('worker_details')
        .update(updates)
        .eq('profile_id', profileId)
        .select()
        .single();
    return WorkerDetails.fromJson(response);
  }

  /// Fetch all worker profiles with their details.
  /// Supports pagination via [limit] and [offset] (default page size 50).
  Future<List<({Profile profile, WorkerDetails details})>> getAllWorkers({
    int limit = 50,
    int offset = 0,
  }) async {
    final profiles = await _client
        .from('profiles')
        .select()
        .eq('profile_type', 'worker')
        .eq('account_status', 'active')
        .range(offset, offset + limit - 1);
    final allDetails = await _client
        .from('worker_details')
        .select();

    final detailsMap = <String, WorkerDetails>{};
    for (final d in allDetails) {
      final wd = WorkerDetails.fromJson(d);
      detailsMap[wd.profileId] = wd;
    }

    final result = <({Profile profile, WorkerDetails details})>[];
    for (final p in profiles) {
      final profile = Profile.fromJson(p);
      final details = detailsMap[profile.id];
      if (details != null) {
        result.add((profile: profile, details: details));
      }
    }
    return result;
  }

  /// Fetch nearby workers using PostGIS ST_DWithin RPC.
  /// Falls back to client-side Haversine if RPC fails.
  Future<List<NearbyWorker>> getNearbyWorkers({
    required LocationPoint employerLocation,
    required double radiusKm,
    List<String> categoryIds = const [],
  }) async {
    try {
      final response = await _client.rpc('nearby_workers', params: {
        'p_lat': employerLocation.lat,
        'p_lng': employerLocation.lng,
        'p_radius_km': radiusKm,
        'p_category_ids': categoryIds,
      });
      return (response as List)
          .map((w) => NearbyWorker.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList();
    } catch (e) {
      debugPrint('nearby_workers RPC failed, falling back to client-side: $e');
      return _getNearbyWorkersFallback(
        employerLocation: employerLocation,
        radiusKm: radiusKm,
        categoryIds: categoryIds,
      );
    }
  }

  Future<List<NearbyWorker>> _getNearbyWorkersFallback({
    required LocationPoint employerLocation,
    required double radiusKm,
    required List<String> categoryIds,
  }) async {
    final workers = await getAllWorkers(limit: 200);
    return workers.where((w) {
      final dist = calculateDistanceKm(
        lat1: w.details.currentLocation.lat,
        lng1: w.details.currentLocation.lng,
        lat2: employerLocation.lat,
        lng2: employerLocation.lng,
      );
      if (dist > radiusKm) return false;
      if (categoryIds.isEmpty) return true;
      return categoryIds.any(
        (cat) => w.details.categoryIds.any(
          (wc) => wc.contains(cat) || cat.contains(wc),
        ),
      );
    }).map((w) {
      final dist = calculateDistanceKm(
        lat1: w.details.currentLocation.lat,
        lng1: w.details.currentLocation.lng,
        lat2: employerLocation.lat,
        lng2: employerLocation.lng,
      );
      return NearbyWorker(
        profileId: w.profile.id,
        displayName: w.profile.displayName,
        categoryIds: w.details.categoryIds,
        bio: w.details.bio,
        averageRating: w.details.averageRating,
        totalJobsCompleted: w.details.totalJobsCompleted,
        distanceKm: dist,
        lat: w.details.currentLocation.lat,
        lng: w.details.currentLocation.lng,
        profilePhotoUrl: w.profile.profilePhotoUrl,
      );
    }).toList();
  }

  // ===========================================================================
  // JOBS
  // ===========================================================================

  /// Create a new job.
  Future<Job> createJob(Job job) async {
    final data = job.toJson();
    // Set PostGIS location geometry
    data['location'] =
        'POINT(${job.pinLocation.lng} ${job.pinLocation.lat})';
    final response = await _client
        .from('jobs')
        .insert(data)
        .select()
        .single();
    return Job.fromJson(response);
  }

  /// Fetch a single job by [id].
  Future<Job?> getJob(String id) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Job.fromJson(response);
  }

  /// Fetch all jobs (newest first).
  /// Supports pagination via [limit] and [offset] (default page size 50).
  Future<List<Job>> getAllJobs({int limit = 50, int offset = 0}) async {
    final response = await _client
        .from('jobs')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((j) => Job.fromJson(j)).toList();
  }

  /// Fetch all jobs posted by [employerProfileId].
  Future<List<Job>> getEmployerJobs(String employerProfileId) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('employer_profile_id', employerProfileId)
        .order('created_at', ascending: false);
    return response.map((j) => Job.fromJson(j)).toList();
  }

  /// Fetch open jobs near a worker using PostGIS ST_DWithin RPC.
  /// Falls back to client-side Haversine if RPC fails.
  Future<List<Job>> getJobsNearWorker({
    required LocationPoint workerLocation,
    required double radiusKm,
    required List<String> categoryIds,
  }) async {
    try {
      final response = await _client.rpc('nearby_jobs', params: {
        'p_lat': workerLocation.lat,
        'p_lng': workerLocation.lng,
        'p_radius_km': radiusKm,
        'p_category_ids': categoryIds,
      });
      return (response as List).map((j) => Job.fromJson(j)).toList();
    } catch (e) {
      debugPrint('nearby_jobs RPC failed, falling back to client-side: $e');
      return _getJobsNearWorkerFallback(
        workerLocation: workerLocation,
        radiusKm: radiusKm,
        categoryIds: categoryIds,
      );
    }
  }

  Future<List<Job>> _getJobsNearWorkerFallback({
    required LocationPoint workerLocation,
    required double radiusKm,
    required List<String> categoryIds,
  }) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(100);

    final jobs = response.map((j) => Job.fromJson(j));
    return jobs.where((job) {
      final dist = calculateDistanceKm(
        lat1: job.pinLocation.lat,
        lng1: job.pinLocation.lng,
        lat2: workerLocation.lat,
        lng2: workerLocation.lng,
      );
      if (dist > radiusKm) return false;
      if (categoryIds.isEmpty) return true;
      return categoryIds.any(
        (cat) => job.categoryId.contains(cat) || cat.contains(job.categoryId),
      );
    }).toList();
  }

  /// Update a job's status and optional hired worker.
  Future<void> updateJobStatus(
    String jobId, {
    required String status,
    String? hiredWorkerProfileId,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (hiredWorkerProfileId != null) {
      data['hired_worker_profile_id'] = hiredWorkerProfileId;
    }
    await _client.from('jobs').update(data).eq('id', jobId);
  }

  // ===========================================================================
  // APPLICATIONS
  // ===========================================================================

  /// Create a new interest application.
  Future<Application> createApplication(Application app) async {
    final response = await _client
        .from('applications')
        .insert(app.toJson())
        .select()
        .single();
    return Application.fromJson(response);
  }

  /// Fetch all applications for a given job.
  Future<List<Application>> getApplicationsForJob(String jobId) async {
    final response = await _client
        .from('applications')
        .select()
        .eq('job_id', jobId);
    return response
        .map((a) => Application.fromJson(a))
        .toList();
  }

  /// Fetch all applications by a worker.
  Future<List<Application>> getApplicationsForWorker(String workerProfileId) async {
    final response = await _client
        .from('applications')
        .select()
        .eq('worker_profile_id', workerProfileId);
    return response
        .map((a) => Application.fromJson(a))
        .toList();
  }

  /// Update application status.
  Future<void> updateApplicationStatus(String id, String status) async {
    await _client
        .from('applications')
        .update({'status': status})
        .eq('id', id);
  }

  /// Batch-update applications for a job (hire one, reject others).
  /// Uses the DB RPC function for atomicity, falls back to sequential.
  Future<void> hireAndReject({
    required String jobId,
    required String hiredWorkerProfileId,
    required List<String> rejectApplicationIds,
  }) async {
    try {
      await _callHireAndRejectRpc(jobId, hiredWorkerProfileId, rejectApplicationIds);
    } catch (rpcError) {
      debugPrint('hireAndReject RPC failed, falling back: $rpcError');
      try {
        if (rejectApplicationIds.isNotEmpty) {
          await _rejectApplications(rejectApplicationIds);
        }
        await _hireApplication(jobId, hiredWorkerProfileId);
      } catch (seqError) {
        debugPrint('hireAndReject sequential fallback failed: $seqError');
        await _rollbackApplications(jobId, hiredWorkerProfileId, rejectApplicationIds);
        rethrow;
      }
    }
  }

  @visibleForTesting
  Future<void> callHireAndRejectRpc(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) {
    return _client.rpc('hire_and_reject', params: {
      'p_job_id': jobId,
      'p_hired_worker_profile_id': hiredWorkerProfileId,
      'p_reject_application_ids': rejectApplicationIds,
    });
  }

  Future<void> _callHireAndRejectRpc(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) {
    return callHireAndRejectRpc(jobId, hiredWorkerProfileId, rejectApplicationIds);
  }

  @visibleForTesting
  Future<void> rejectApplications(List<String> ids) async {
    await _client
        .from('applications')
        .update({'status': 'rejected'})
        .inFilter('id', ids);
  }

  Future<void> _rejectApplications(List<String> ids) => rejectApplications(ids);

  @visibleForTesting
  Future<void> hireApplication(String jobId, String workerProfileId) async {
    await _client
        .from('applications')
        .update({'status': 'hired'})
        .eq('job_id', jobId)
        .eq('worker_profile_id', workerProfileId);
  }

  Future<void> _hireApplication(String jobId, String workerProfileId) =>
      hireApplication(jobId, workerProfileId);

  @visibleForTesting
  Future<void> rollbackApplications(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) async {
    await _client
        .from('applications')
        .update({'status': 'interested'})
        .eq('job_id', jobId)
        .eq('worker_profile_id', hiredWorkerProfileId);
    if (rejectApplicationIds.isNotEmpty) {
      await _client
          .from('applications')
          .update({'status': 'interested'})
          .inFilter('id', rejectApplicationIds);
    }
  }

  Future<void> _rollbackApplications(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) => rollbackApplications(jobId, hiredWorkerProfileId, rejectApplicationIds);

  /// Fetch applications for multiple jobs in a single query (avoids N+1).
  Future<List<Application>> getApplicationsForJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];
    final response = await _client
        .from('applications')
        .select()
        .inFilter('job_id', jobIds)
        .order('applied_at', ascending: false);
    return response.map((a) => Application.fromJson(a)).toList();
  }

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  /// Get or create a conversation between employer and worker for a job.
  Future<Conversation> getOrCreateConversation({
    required String jobId,
    required String employerProfileId,
    required String workerProfileId,
  }) async {
    final existing = await _findConversation(jobId, workerProfileId);
    if (existing != null) {
      return Conversation.fromJson(existing);
    }

    try {
      final response = await _insertConversation(jobId, employerProfileId, workerProfileId);
      return Conversation.fromJson(response);
    } catch (e) {
      debugPrint('Conversation insert conflict (race): $e');
      final retry = await _findConversation(jobId, workerProfileId);
      if (retry != null) return Conversation.fromJson(retry);
      rethrow;
    }
  }

  @visibleForTesting
  Future<Map<String, dynamic>?> findConversation(String jobId, String workerProfileId) {
    return _client
        .from('conversations')
        .select()
        .eq('job_id', jobId)
        .eq('worker_profile_id', workerProfileId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _findConversation(String jobId, String workerProfileId) {
    return findConversation(jobId, workerProfileId);
  }

  @visibleForTesting
  Future<Map<String, dynamic>> insertConversation(
    String jobId,
    String employerProfileId,
    String workerProfileId,
  ) {
    return _client
        .from('conversations')
        .insert({
          'job_id': jobId,
          'employer_profile_id': employerProfileId,
          'worker_profile_id': workerProfileId,
          'last_message_text': 'Conversation started',
          'last_message_time': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
  }

  Future<Map<String, dynamic>> _insertConversation(
    String jobId,
    String employerProfileId,
    String workerProfileId,
  ) {
    return insertConversation(jobId, employerProfileId, workerProfileId);
  }

  /// Fetch all conversations involving [profileId].
  Future<List<Conversation>> getConversations(String profileId) async {
    final response = await _client
        .from('conversations')
        .select()
        .or('employer_profile_id.eq.$profileId,worker_profile_id.eq.$profileId')
        .order('last_message_time', ascending: false);
    return response
        .map((c) => Conversation.fromJson(c))
        .toList();
  }

  /// Update a conversation's last message text and time.
  Future<void> updateConversationLastMessage(
    String conversationId, {
    required String lastMessageText,
    required DateTime lastMessageTime,
  }) async {
    await _client.from('conversations').update({
      'last_message_text': lastMessageText,
      'last_message_time': lastMessageTime.toIso8601String(),
    }).eq('id', conversationId);
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  /// Send a message in a conversation.
  Future<Message> sendMessage(Message message) async {
    final data = Map<String, dynamic>.of(message.toJson());
    data.remove('read_at'); // Don't set read_at on send
    final response = await _client
        .from('messages')
        .insert(data)
        .select()
        .single();
    return Message.fromJson(response);
  }

  /// Fetch all messages for a conversation (oldest first).
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);
    return response
        .map((m) => Message.fromJson(m))
        .toList();
  }

  /// Subscribe to new messages in a conversation (for live chat).
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Message message) onMessage,
  ) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            column: 'conversation_id',
            type: PostgresChangeFilterType.eq,
            value: conversationId,
          ),
          callback: (payload) {
            final msg =
                Message.fromJson(payload.newRecord);
            onMessage(msg);
          },
        )
        .subscribe();
  }

  // ===========================================================================
  // REVIEWS
  // ===========================================================================

  /// Create a new review.
  Future<Review> createReview(Review review) async {
    final response = await _client
        .from('reviews')
        .insert(review.toJson())
        .select()
        .single();
    return Review.fromJson(response);
  }

  /// Fetch all reviews for a profile (as reviewee).
  Future<List<Review>> getReviewsForProfile(String profileId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('reviewee_profile_id', profileId)
        .order('created_at', ascending: false);
    return response
        .map((r) => Review.fromJson(r))
        .toList();
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  /// Create a notification.
  Future<void> createNotification(NotificationItem notification) async {
    await _client
        .from('notifications')
        .insert(notification.toJson());
  }

  /// Fetch all notifications for a profile.
  Future<List<NotificationItem>> getNotifications(String profileId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return response
        .map((n) => NotificationItem.fromJson(n))
        .toList();
  }

  /// Mark all unread notifications as read for a profile.
  Future<void> markNotificationsRead(String profileId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', profileId)
        .eq('is_read', false);
  }

  /// Subscribe to new notifications for a profile.
  RealtimeChannel subscribeToNotifications(
    String profileId,
    void Function(NotificationItem notification) onNotification,
  ) {
    return _client
        .channel('notifications:$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            column: 'profile_id',
            type: PostgresChangeFilterType.eq,
            value: profileId,
          ),
          callback: (payload) {
            final notif = NotificationItem.fromJson(
                payload.newRecord);
            onNotification(notif);
          },
        )
        .subscribe();
  }

  Future<void> saveDeviceToken(String token, String platform) async {
    final profileId = _client.auth.currentUser?.id;
    if (profileId == null) return;
    await _client.from('device_tokens').upsert({
      'id': 'dt-$profileId-$platform',
      'profile_id': profileId,
      'token': token,
      'platform': platform,
    });
  }

  // ===========================================================================
  // FAVORITES
  // ===========================================================================

  Future<List<Favorite>> getFavorites(String profileId) async {
    final response = await _client
        .from('favorites')
        .select()
        .eq('profile_id', profileId);
    return response.map((f) => Favorite.fromJson(f)).toList();
  }

  Future<void> addFavorite(String profileId, String favoritedProfileId) async {
    await _client.from('favorites').upsert({
      'id': 'fav-$profileId-$favoritedProfileId',
      'profile_id': profileId,
      'favorited_profile_id': favoritedProfileId,
    });
  }

  Future<void> removeFavorite(String id) async {
    await _client.from('favorites').delete().eq('id', id);
  }

  // ===========================================================================
  // REPORTS
  // ===========================================================================

  Future<void> createReport(Report report) async {
    await _client.from('reports').insert(report.toJson());
  }

  Future<List<Report>> getReports(String profileId) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('reporter_profile_id', profileId)
        .order('created_at', ascending: false);
    return response.map((r) => Report.fromJson(r)).toList();
  }
}
