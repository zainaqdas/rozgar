import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/location_point.dart';
import '../models/review.dart';
import '../services/supabase_service.dart';
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
    } catch (e) {
      _lastOperationError = 'Failed to save employer profile';
      notifyListeners();
    }
  }

  void updateWorkerBio(String bio) {
    if (_workerDetails == null) return;
    final safeBio = sanitizeInput(bio);
    _workerDetails = _workerDetails!.copyWith(bio: safeBio);
    notifyListeners();
    _fireAndForget('updateBio', () => _supabase.updateWorkerDetails(
      _workerDetails!.profileId,
      {'bio': safeBio},
    ));
  }

  void toggleWorkerOnline(bool online) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(isOnlineForMap: online);
    notifyListeners();
    _fireAndForget('toggleOnline', () => _supabase.updateWorkerDetails(
      _workerDetails!.profileId,
      {'is_online_for_map': online},
    ));
  }

  void updateProfilePhoto(String photoUrl) {
    final profile = activeProfile;
    if (profile == null) return;
    final updated = profile.copyWith(profilePhotoUrl: photoUrl);
    if (profile.profileType == ProfileType.employer) {
      _employerProfile = updated;
    } else {
      _workerProfile = updated;
    }
    notifyListeners();
    _fireAndForget('updateProfilePhoto', () => _supabase.updateProfile(
      profile.id,
      {'profile_photo_url': photoUrl},
    ));
  }

  void updateWorkerRadius(double radiusKm) {
    if (_workerDetails == null) return;
    _workerDetails = _workerDetails!.copyWith(notificationRadiusKm: radiusKm);
    notifyListeners();
    _fireAndForget('updateRadius', () => _supabase.updateWorkerDetails(
      _workerDetails!.profileId,
      {'notification_radius_km': radiusKm},
    ));
  }

  void _fireAndForget(String label, Future<dynamic> Function() task) {
    task().then((_) {}, onError: (e) {
      debugPrint('$label failed: $e');
      _lastOperationError ??= '$label failed';
      notifyListeners();
    });
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
    _fireAndForget('addReview', () => _supabase.createReview(review));
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
