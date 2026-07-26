import 'location_point.dart';

enum JobStatus { open, hired, completed, cancelled, expired }
enum JobUrgency { instant, today, scheduled }
enum BudgetType { fixed, hourly, negotiable }

class AIExtractedSummary {
  final String category;
  final JobUrgency urgency;
  final double suggestedBudget;
  final double estimatedDuration;
  final List<String> requiredSkills;

  const AIExtractedSummary({
    this.category = '',
    this.urgency = JobUrgency.today,
    this.suggestedBudget = 0,
    this.estimatedDuration = 1,
    this.requiredSkills = const [],
  });

  factory AIExtractedSummary.fromJson(Map<String, dynamic> json) =>
      AIExtractedSummary(
        category: json['category'] as String? ?? '',
        urgency: _parseUrgency(json['urgency']),
        suggestedBudget: (json['suggested_budget'] as num?)?.toDouble() ?? 0,
        estimatedDuration:
            (json['estimated_duration'] as num?)?.toDouble() ?? 1,
        requiredSkills: (json['required_skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  static JobUrgency _parseUrgency(dynamic v) {
    if (v == 'instant') return JobUrgency.instant;
    if (v == 'scheduled') return JobUrgency.scheduled;
    return JobUrgency.today;
  }
}

class Job {
  final String id;
  final String employerProfileId;
  final String categoryId;
  final String title;
  final String description;
  final AIExtractedSummary? aiExtractedSummary;
  final double budgetAmount;
  final BudgetType budgetType;
  final LocationPoint pinLocation;
  final JobStatus status;
  final JobUrgency urgency;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final String? hiredWorkerProfileId;

  const Job({
    required this.id,
    required this.employerProfileId,
    required this.categoryId,
    this.title = '',
    this.description = '',
    this.aiExtractedSummary,
    this.budgetAmount = 0,
    this.budgetType = BudgetType.fixed,
    required this.pinLocation,
    this.status = JobStatus.open,
    this.urgency = JobUrgency.today,
    this.scheduledFor,
    required this.createdAt,
    this.hiredWorkerProfileId,
  });

  Job copyWith({JobStatus? status, String? hiredWorkerProfileId}) => Job(
        id: id,
        employerProfileId: employerProfileId,
        categoryId: categoryId,
        title: title,
        description: description,
        aiExtractedSummary: aiExtractedSummary,
        budgetAmount: budgetAmount,
        budgetType: budgetType,
        pinLocation: pinLocation,
        status: status ?? this.status,
        urgency: urgency,
        scheduledFor: scheduledFor,
        createdAt: createdAt,
        hiredWorkerProfileId:
            hiredWorkerProfileId ?? this.hiredWorkerProfileId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employer_profile_id': employerProfileId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'ai_extracted_summary': aiExtractedSummary != null
            ? {
                'category': aiExtractedSummary!.category,
                'urgency': aiExtractedSummary!.urgency.name,
                'suggested_budget': aiExtractedSummary!.suggestedBudget,
                'estimated_duration': aiExtractedSummary!.estimatedDuration,
                'required_skills': aiExtractedSummary!.requiredSkills,
              }
            : null,
        'budget_amount': budgetAmount,
        'budget_type': budgetType.name,
        'pin_location': pinLocation.toJson(),
        'status': status.name,
        'urgency': urgency.name,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'hired_worker_profile_id': hiredWorkerProfileId,
      };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        employerProfileId: json['employer_profile_id'] as String,
        categoryId: json['category_id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        aiExtractedSummary: json['ai_extracted_summary'] != null
            ? AIExtractedSummary.fromJson(
                json['ai_extracted_summary'] as Map<String, dynamic>)
            : null,
        budgetAmount: (json['budget_amount'] as num?)?.toDouble() ?? 0,
        budgetType: _parseBudgetType(json['budget_type']),
        pinLocation: LocationPoint.fromJson(
            json['pin_location'] as Map<String, dynamic>),
        status: _parseStatus(json['status']),
        urgency: _parseUrgency(json['urgency']),
        scheduledFor: json['scheduled_for'] != null
            ? DateTime.parse(json['scheduled_for'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        hiredWorkerProfileId:
            json['hired_worker_profile_id'] as String?,
      );

  static BudgetType _parseBudgetType(dynamic v) {
    if (v == 'hourly') return BudgetType.hourly;
    if (v == 'negotiable') return BudgetType.negotiable;
    return BudgetType.fixed;
  }

  static JobStatus _parseStatus(dynamic v) {
    switch (v) {
      case 'hired':
        return JobStatus.hired;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'expired':
        return JobStatus.expired;
      default:
        return JobStatus.open;
    }
  }

  static JobUrgency _parseUrgency(dynamic v) {
    if (v == 'instant') return JobUrgency.instant;
    if (v == 'scheduled') return JobUrgency.scheduled;
    return JobUrgency.today;
  }
}
