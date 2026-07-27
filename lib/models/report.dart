enum ReportStatus { open, reviewed, resolved, dismissed }

class Report {
  final String id;
  final String reporterProfileId;
  final String reportedProfileId;
  final String? jobId;
  final String reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterProfileId,
    required this.reportedProfileId,
    this.jobId,
    required this.reason,
    this.details,
    this.status = ReportStatus.open,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporter_profile_id': reporterProfileId,
        'reported_profile_id': reportedProfileId,
        'job_id': jobId,
        'reason': reason,
        'details': details,
        'status': _statusToSnake(status),
        'created_at': createdAt.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterProfileId: json['reporter_profile_id'] as String,
        reportedProfileId: json['reported_profile_id'] as String,
        jobId: json['job_id'] as String?,
        reason: json['reason'] as String? ?? '',
        details: json['details'] as String?,
        status: _parseStatus(json['status']),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static ReportStatus _parseStatus(dynamic v) {
    switch (v) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.open;
    }
  }

  static String _statusToSnake(ReportStatus s) {
    return s.name;
  }
}
