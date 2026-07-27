enum ApplicationStatus { interested, shortlisted, hired, rejected }

class Application {
  final String id;
  final String jobId;
  final String workerProfileId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? message;
  final String? aiMatchNote;

  const Application({
    required this.id,
    required this.jobId,
    required this.workerProfileId,
    this.status = ApplicationStatus.interested,
    required this.appliedAt,
    this.message,
    this.aiMatchNote,
  });

  Application copyWith({
    ApplicationStatus? status,
    String? aiMatchNote,
  }) =>
      Application(
        id: id,
        jobId: jobId,
        workerProfileId: workerProfileId,
        status: status ?? this.status,
        appliedAt: appliedAt,
        message: message,
        aiMatchNote: aiMatchNote ?? this.aiMatchNote,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'worker_profile_id': workerProfileId,
        'status': status.name,
        'applied_at': appliedAt.toIso8601String(),
        'message': message,
        'ai_match_note': aiMatchNote,
      };

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        workerProfileId: json['worker_profile_id'] as String,
        status: _parseStatus(json['status']),
        appliedAt: DateTime.tryParse(json['applied_at'] as String? ?? '') ??
            DateTime.now(),
        message: json['message'] as String?,
        aiMatchNote: json['ai_match_note'] as String?,
      );

  static ApplicationStatus _parseStatus(dynamic v) {
    switch (v) {
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'hired':
        return ApplicationStatus.hired;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.interested;
    }
  }
}
