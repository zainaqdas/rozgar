import 'location_point.dart';

enum ProfileType { employer, worker }
enum IdVerificationStatus { none, pending, verified }
enum AccountStatus { active, suspended }
enum AvailabilityStatus {
  today,
  tomorrow,
  weekdays,
  weekends,
  morning,
  evening,
  busy,
  offline,
}

class Profile {
  final String id;
  final String authIdentityId;
  final ProfileType profileType;
  final String displayName;
  final String profilePhotoUrl;
  final String? phone;
  final String city;
  final LocationPoint homeLocation;
  final DateTime createdAt;
  final bool isVerified;
  final IdVerificationStatus idVerificationStatus;
  final AccountStatus accountStatus;
  final double onboardingCompletionPct;

  const Profile({
    required this.id,
    required this.authIdentityId,
    required this.profileType,
    this.displayName = '',
    this.profilePhotoUrl = '',
    this.phone,
    this.city = 'Lahore',
    required this.homeLocation,
    required this.createdAt,
    this.isVerified = false,
    this.idVerificationStatus = IdVerificationStatus.none,
    this.accountStatus = AccountStatus.active,
    this.onboardingCompletionPct = 0,
  });

  Profile copyWith({
    String? displayName,
    String? profilePhotoUrl,
    String? phone,
    String? city,
    LocationPoint? homeLocation,
    bool? isVerified,
    IdVerificationStatus? idVerificationStatus,
    AccountStatus? accountStatus,
    double? onboardingCompletionPct,
  }) =>
      Profile(
        id: id,
        authIdentityId: authIdentityId,
        profileType: profileType,
        displayName: displayName ?? this.displayName,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        phone: phone ?? this.phone,
        city: city ?? this.city,
        homeLocation: homeLocation ?? this.homeLocation,
        createdAt: createdAt,
        isVerified: isVerified ?? this.isVerified,
        idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
        accountStatus: accountStatus ?? this.accountStatus,
        onboardingCompletionPct: onboardingCompletionPct ?? this.onboardingCompletionPct,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_identity_id': authIdentityId,
        'profile_type': profileType.name,
        'display_name': displayName,
        'profile_photo_url': profilePhotoUrl,
        'phone': phone,
        'city': city,
        'home_location': homeLocation.toJson(),
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
        'id_verification_status': idVerificationStatus.name,
        'account_status': accountStatus.name,
        'onboarding_completion_pct': onboardingCompletionPct,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        authIdentityId: json['auth_identity_id'] as String,
        profileType: json['profile_type'] == 'worker'
            ? ProfileType.worker
            : ProfileType.employer,
        displayName: json['display_name'] as String? ?? '',
        profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
        phone: json['phone'] as String?,
        city: json['city'] as String? ?? 'Lahore',
        homeLocation: json['home_location'] != null
            ? LocationPoint.fromJson(
                json['home_location'] as Map<String, dynamic>)
            : const LocationPoint(lat: 31.5204, lng: 74.3587),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        isVerified: json['is_verified'] as bool? ?? false,
        idVerificationStatus: _parseIdStatus(json['id_verification_status']),
        accountStatus: _parseAccountStatus(json['account_status']),
        onboardingCompletionPct:
            (json['onboarding_completion_pct'] as num?)?.toDouble() ?? 0,
      );

  static IdVerificationStatus _parseIdStatus(dynamic v) {
    if (v == 'pending') return IdVerificationStatus.pending;
    if (v == 'verified') return IdVerificationStatus.verified;
    return IdVerificationStatus.none;
  }

  static AccountStatus _parseAccountStatus(dynamic v) {
    if (v == 'suspended') return AccountStatus.suspended;
    return AccountStatus.active;
  }
}

class WorkerDetails {
  final String profileId;
  final List<String> categoryIds;
  final String bio;
  final int yearsExperience;
  final String rateNote;
  final AvailabilityStatus availabilityStatus;
  final double notificationRadiusKm;
  final bool isOnlineForMap;
  final LocationPoint currentLocation;
  final List<String> portfolioMedia;
  final double averageRating;
  final int totalJobsCompleted;
  final int responseTimeAvgMinutes;
  final bool? isFeatured;

  const WorkerDetails({
    required this.profileId,
    this.categoryIds = const [],
    this.bio = '',
    this.yearsExperience = 0,
    this.rateNote = '',
    this.availabilityStatus = AvailabilityStatus.today,
    this.notificationRadiusKm = 15,
    this.isOnlineForMap = true,
    required this.currentLocation,
    this.portfolioMedia = const [],
    this.averageRating = 5.0,
    this.totalJobsCompleted = 0,
    this.responseTimeAvgMinutes = 5,
    this.isFeatured,
  });

  WorkerDetails copyWith({
    String? bio,
    List<String>? categoryIds,
    int? yearsExperience,
    String? rateNote,
    AvailabilityStatus? availabilityStatus,
    double? notificationRadiusKm,
    bool? isOnlineForMap,
    LocationPoint? currentLocation,
    List<String>? portfolioMedia,
    double? averageRating,
    int? totalJobsCompleted,
    int? responseTimeAvgMinutes,
    bool? isFeatured,
  }) =>
      WorkerDetails(
        profileId: profileId,
        bio: bio ?? this.bio,
        categoryIds: categoryIds ?? this.categoryIds,
        yearsExperience: yearsExperience ?? this.yearsExperience,
        rateNote: rateNote ?? this.rateNote,
        availabilityStatus: availabilityStatus ?? this.availabilityStatus,
        notificationRadiusKm:
            notificationRadiusKm ?? this.notificationRadiusKm,
        isOnlineForMap: isOnlineForMap ?? this.isOnlineForMap,
        currentLocation: currentLocation ?? this.currentLocation,
        portfolioMedia: portfolioMedia ?? this.portfolioMedia,
        averageRating: averageRating ?? this.averageRating,
        totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
        responseTimeAvgMinutes:
            responseTimeAvgMinutes ?? this.responseTimeAvgMinutes,
        isFeatured: isFeatured ?? this.isFeatured,
      );

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'category_ids': categoryIds,
        'bio': bio,
        'years_experience': yearsExperience,
        'rate_note': rateNote,
        'availability_status': availabilityStatus.name,
        'notification_radius_km': notificationRadiusKm,
        'is_online_for_map': isOnlineForMap,
        'current_location': currentLocation.toJson(),
        'portfolio_media': portfolioMedia,
        'average_rating': averageRating,
        'total_jobs_completed': totalJobsCompleted,
        'response_time_avg_minutes': responseTimeAvgMinutes,
        'is_featured': isFeatured,
      };

  factory WorkerDetails.fromJson(Map<String, dynamic> json) => WorkerDetails(
        profileId: json['profile_id'] as String,
        categoryIds: (json['category_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        bio: json['bio'] as String? ?? '',
        yearsExperience: (json['years_experience'] as num?)?.toInt() ?? 0,
        rateNote: json['rate_note'] as String? ?? '',
        availabilityStatus: _parseAvailability(json['availability_status']),
        notificationRadiusKm:
            (json['notification_radius_km'] as num?)?.toDouble() ?? 15,
        isOnlineForMap: json['is_online_for_map'] as bool? ?? true,
        currentLocation: LocationPoint.fromJson(
            json['current_location'] as Map<String, dynamic>),
        portfolioMedia: (json['portfolio_media'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        averageRating:
            (json['average_rating'] as num?)?.toDouble() ?? 5.0,
        totalJobsCompleted:
            (json['total_jobs_completed'] as num?)?.toInt() ?? 0,
        responseTimeAvgMinutes:
            (json['response_time_avg_minutes'] as num?)?.toInt() ?? 5,
        isFeatured: json['is_featured'] as bool?,
      );

  static AvailabilityStatus _parseAvailability(dynamic v) {
    switch (v) {
      case 'tomorrow':
        return AvailabilityStatus.tomorrow;
      case 'weekdays':
        return AvailabilityStatus.weekdays;
      case 'weekends':
        return AvailabilityStatus.weekends;
      case 'morning':
        return AvailabilityStatus.morning;
      case 'evening':
        return AvailabilityStatus.evening;
      case 'busy':
        return AvailabilityStatus.busy;
      case 'offline':
        return AvailabilityStatus.offline;
      default:
        return AvailabilityStatus.today;
    }
  }
}
