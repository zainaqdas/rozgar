import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/location_point.dart';
import '../models/review.dart';
import '../services/push_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../utils/sanitize.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ProfileNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  Profile? _employerProfile;
  Profile? _workerProfile;
  WorkerDetails? _workerDetails;
  String? _activeProfileId;
  List<Review> _reviews = [];
  String? _lastOperationError;

  Profile? get employerProfile => _employerProfile;
  Profile? get workerProfile => _workerProfile;
  WorkerDetails? get workerDetails => _workerDetails;
  String? get activeProfileId => _activeProfileId;
  List<Review> get reviews => List.unmodifiable(_reviews);
  String? get lastOperationError => _lastOperationError;

  Profile? get activeProfile {
    if (_activeProfileId == _employerProfile?.id) return _employerProfile;
    if (_activeProfileId == _workerProfile?.id) return _workerProfile;
    return _employerProfile;
  }

  ProfileType get activeProfileType =>
      activeProfile?.profileType ?? ProfileType.employer;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  void setProfiles(List<Profile> profiles, WorkerDetails? details) {
    for (final profile in profiles) {
      if (profile.profileType == ProfileType.employer) {
        _employerProfile = profile;
      } else if (profile.profileType == ProfileType.worker) {
        _workerProfile = profile;
        _workerDetails = details;
      }
    }
    if (_employerProfile != null) {
      _activeProfileId = _employerProfile!.id;
    } else if (_workerProfile != null) {
      _activeProfileId = _workerProfile!.id;
    }
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

  Future<void> completeWorkerOnboarding({
    required String authId,
    required String displayName,
    required List<String> categoryIds,
    required String bio,
    required int yearsExperience,
    required LocationPoint homeLocation,
  }) async {
    final safeName = sanitizeInput(displayName);
    final safeBio = sanitizeInput(bio);
    _workerProfile = Profile(
      id: 'wrk-$authId',
      authIdentityId: authId,
      profileType: ProfileType.worker,
      displayName: safeName,
      profilePhotoUrl: '',
      city: (homeLocation.city != null && homeLocation.city!.isNotEmpty)
          ? homeLocation.city!
          : 'Lahore',
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
      bio: safeBio,
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
    notifyListeners();
    try {
      await _supabase.createProfile(_workerProfile!);
      await _supabase.createWorkerDetails(_workerDetails!);
      // Profile rows now exist in Supabase, so the FCM token can be
      // registered against them (PushService init runs pre-auth at cold
      // start, so its first attempt is a no-op for new signups).
      await PushService.instance.registerCurrentToken();
    } catch (e) {
      _lastOperationError = 'Failed to save worker profile';
      notifyListeners();
    }
  }

  Future<void> completeEmployerOnboarding({
    required String authId,
    required String displayName,
    required LocationPoint homeLocation,
  }) async {
    final safeName = sanitizeInput(displayName);
    _employerProfile = Profile(
      id: authId,
      authIdentityId: authId,
      profileType: ProfileType.employer,
      displayName: safeName,
      profilePhotoUrl: '',
      city: (homeLocation.city != null && homeLocation.city!.isNotEmpty)
          ? homeLocation.city!
          : 'Lahore',
      homeLocation: homeLocation,
      createdAt: DateTime.now(),
      isVerified: true,
      idVerificationStatus: IdVerificationStatus.verified,
      accountStatus: AccountStatus.active,
      onboardingCompletionPct: 100,
    );
    _activeProfileId = _employerProfile!.id;
    notifyListeners();
    try {
      await _supabase.createProfile(_employerProfile!);
      // See note in completeWorkerOnboarding — register FCM token now
      // that the profile row exists.
      await PushService.instance.registerCurrentToken();
    } catch (e) {
      _lastOperationError = 'Failed to save employer profile';
      notifyListeners();
    }
  }

  void updateWorkerBio(String bio) {
    updateBio(bio);
  }

  void updateBio(String bio) {
    final profile = _workerDetails;
    if (profile == null) return;
    final safeBio = sanitizeInput(bio);
    _workerDetails = _workerDetails!.copyWith(bio: safeBio);
    notifyListeners();
    _fireAndForget(
      'update_worker_details',
      {
        'profile_id': profile.profileId,
        'updates': {'bio': safeBio},
      },
      () => _supabase.updateWorkerDetails(profile.profileId, {'bio': safeBio}),
    );
  }

  void toggleWorkerOnline(bool online) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(isOnlineForMap: online);
    notifyListeners();
    _fireAndForget(
      'update_worker_details',
      {
        'profile_id': _workerDetails!.profileId,
        'updates': {'is_online_for_map': online},
      },
      () => _supabase.updateWorkerDetails(_workerDetails!.profileId, {
        'is_online_for_map': online,
      }),
    );
  }

  void updateProfilePhoto(String photoUrl) {
    final profile = activeProfile;
    if (profile == null) return;
    if (profile.profileType == ProfileType.worker) {
      _workerProfile = _workerProfile?.copyWith(profilePhotoUrl: photoUrl);
    } else {
      _employerProfile = _employerProfile?.copyWith(profilePhotoUrl: photoUrl);
    }
    notifyListeners();
    _fireAndForget(
      'profile_photo',
      {'profile_id': profile.id, 'photo_url': photoUrl},
      () =>
          _supabase.updateProfile(profile.id, {'profile_photo_url': photoUrl}),
    );
  }

  void updateWorkerRadius(double radiusKm) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(notificationRadiusKm: radiusKm);
    notifyListeners();
    _fireAndForget(
      'update_worker_details',
      {
        'profile_id': _workerDetails!.profileId,
        'updates': {'notification_radius_km': radiusKm},
      },
      () => _supabase.updateWorkerDetails(_workerDetails!.profileId, {
        'notification_radius_km': radiusKm,
      }),
    );
  }

  void _fireAndForget(
    String type,
    Map<String, dynamic> payload,
    Future<dynamic> Function() task,
  ) {
    task().then(
      (_) {},
      onError: (e) {
        debugPrint('$type failed: $e');
        _lastOperationError ??= '$type failed';
        notifyListeners();
        // Enqueue operation for retry
        final syncService = SyncService.instance;
        syncService.enqueue(type, payload);
      },
    );
  }

  void setReviews(List<Review> reviews) {
    _reviews = reviews;
    notifyListeners();
  }

  void addReview(
    String jobId,
    String revieweeProfileId,
    int rating,
    String comment,
  ) {
    final reviewerId = _activeProfileId;
    if (reviewerId == null) return;
    final review = Review(
      id: 'rev-${_uuid.v4()}',
      jobId: jobId,
      reviewerProfileId: reviewerId,
      revieweeProfileId: revieweeProfileId,
      rating: rating,
      comment: sanitizeInput(comment),
      createdAt: DateTime.now(),
    );
    _reviews.insert(0, review);
    notifyListeners();
    _fireAndForget(
      'add_review',
      review.toJson(),
      () => _supabase.createReview(review),
    );
  }

  void clear() {
    _employerProfile = null;
    _workerProfile = null;
    _workerDetails = null;
    _activeProfileId = null;
    _reviews = [];
    _lastOperationError = null;
    notifyListeners();
  }
}
