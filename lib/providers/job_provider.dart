import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/conversation.dart';
import '../models/notification_item.dart';
import '../models/location_point.dart';
import '../services/supabase_service.dart';
import '../providers/worker_provider.dart' show WorkerEntry;
import '../utils/geo.dart';
import '../utils/sanitize.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class JobNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<Job> _jobs = [];
  List<Application> _applications = [];
  String? _lastOperationError;

  List<Job> get jobs => List.unmodifiable(_jobs);
  List<Application> get applications => List.unmodifiable(_applications);
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  /// Jobs older than this many days are auto-expired on load.
  static const int expiryDays = 14;

  void setJobs(List<Job> jobs) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: expiryDays));
    final expiredIds = <String>[];

    _jobs = jobs.map((job) {
      if (job.status == JobStatus.open && job.createdAt.isBefore(cutoff)) {
        expiredIds.add(job.id);
        return job.copyWith(status: JobStatus.expired);
      }
      return job;
    }).toList();

    notifyListeners();

    // Persist expiry to Supabase fire-and-forget
    for (final id in expiredIds) {
      _fireAndForget('expireJob:$id',
          () => _supabase.updateJobStatus(id, status: 'expired'));
    }
  }

  void setApplications(List<Application> applications) {
    _applications = applications;
    notifyListeners();
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
    List<WorkerEntry> nearbyWorkers = const [],
    void Function(NotificationItem)? onNotify,
  }) {
    final safeTitle = sanitizeInput(title);
    final safeDescription = sanitizeInput(description);
    final jobId = 'job-${_uuid.v4()}';
    final job = Job(
      id: jobId,
      employerProfileId: employerProfileId,
      categoryId: categoryId,
      title: safeTitle,
      description: safeDescription,
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

    _fireAndForget('createJob', () async {
      await _supabase.createJob(job);
      for (final worker in nearbyWorkers) {
        final dist = calculateDistanceKm(
          lat1: job.pinLocation.lat,
          lng1: job.pinLocation.lng,
          lat2: worker.details.currentLocation.lat,
          lng2: worker.details.currentLocation.lng,
        );
        if (dist <= worker.details.notificationRadiusKm) {
          final notif = NotificationItem(
            id: 'notif-${_uuid.v4()}',
            profileId: worker.profile.id,
            type: NotificationType.newJobRadius,
            titleEn: 'New Job Available Near You!',
            titleUr: 'آپ کے قریب نیا کام دستیاب ہے!',
            bodyEn:
                'A $safeTitle job is ${dist.toStringAsFixed(1)} km from your location.',
            bodyUr:
                '$safeTitle کا کام آپ سے صرف ${dist.toStringAsFixed(1)} کلومیٹر دور ہے۔',
            isRead: false,
            createdAt: DateTime.now(),
            payload: {'jobId': job.id},
          );
          await _supabase.createNotification(notif);
        }
      }
    });

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
      return categoryIds
          .any((cat) => job.categoryId.contains(cat) || cat.contains(job.categoryId));
    }).toList();
  }

  List<Job> getEmployerJobs(String employerProfileId) {
    return _jobs.where((j) => j.employerProfileId == employerProfileId).toList();
  }

  void expressInterest(
    String jobId, {
    required String workerProfileId,
    required String workerDisplayName,
    String message =
        'Assalam-o-Alaikum! I am available to start work immediately.',
    void Function(NotificationItem)? onNotify,
  }) {
    final alreadyApplied = _applications.any(
      (a) => a.jobId == jobId && a.workerProfileId == workerProfileId,
    );
    if (alreadyApplied) return;
    final safeMessage = sanitizeInput(message);
    final app = Application(
      id: 'app-${_uuid.v4()}',
      jobId: jobId,
      workerProfileId: workerProfileId,
      status: ApplicationStatus.interested,
      appliedAt: DateTime.now(),
      message: safeMessage,
      aiMatchNote: '⚡ Verified candidate, top rated in category nearby.',
    );
    _applications.add(app);

    final job = _jobs.where((j) => j.id == jobId).firstOrNull;
    if (job != null) {
      final notif = NotificationItem(
        id: 'notif-${_uuid.v4()}',
        profileId: job.employerProfileId,
        type: NotificationType.workerInterested,
        titleEn: 'Worker Interested in your Job',
        titleUr: 'کاریگر نے آپ کے کام میں دلچسپی ظاہر کی',
        bodyEn: '$workerDisplayName expressed interest in "${job.title}".',
        bodyUr: '$workerDisplayName نے آپ کے کام میں دلچسپی ظاہر کی ہے۔',
        isRead: false,
        createdAt: DateTime.now(),
        payload: {'jobId': jobId},
      );
      _fireAndForget('expressInterest:notif',
          () => _supabase.createNotification(notif));
    }
    notifyListeners();

    _fireAndForget(
        'expressInterest:app', () => _supabase.createApplication(app));
  }

  void hireWorker(
    String jobId,
    String hiredWorkerProfileId,
    String employerProfileId, {
    void Function(Conversation)? onConversationCreated,
  }) {
    final rejectAppIds = _applications
        .where((a) =>
            a.jobId == jobId && a.workerProfileId != hiredWorkerProfileId)
        .map((a) => a.id)
        .toList();

    _jobs = _jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(
          status: JobStatus.hired,
          hiredWorkerProfileId: hiredWorkerProfileId,
        );
      }
      return j;
    }).toList();

    _applications = _applications.map((a) {
      if (a.jobId == jobId) {
        if (a.workerProfileId == hiredWorkerProfileId) {
          return a.copyWith(status: ApplicationStatus.hired);
        }
        return a.copyWith(status: ApplicationStatus.rejected);
      }
      return a;
    }).toList();

    final job = _jobs.where((j) => j.id == jobId).firstOrNull;
    if (job != null) {
      final notif = NotificationItem(
        id: 'notif-${_uuid.v4()}',
        profileId: hiredWorkerProfileId,
        type: NotificationType.jobHired,
        titleEn: 'You are Hired!',
        titleUr: 'مبارک ہو! آپ کا انتخاب ہو گیا ہے',
        bodyEn: 'You were hired for "${job.title}". Tap to open chat.',
        bodyUr: 'آپ کو "${job.title}" کے لیے منتخب کر لیا گیا ہے۔',
        isRead: false,
        createdAt: DateTime.now(),
        payload: {'jobId': jobId},
      );
      _fireAndForget('hireWorker:notif',
          () => _supabase.createNotification(notif));
    }
    notifyListeners();

    _fireAndForget('hireWorker:update',
        () => _supabase.updateJobStatus(jobId, status: 'hired', hiredWorkerProfileId: hiredWorkerProfileId));
    if (rejectAppIds.isNotEmpty) {
      _fireAndForget('hireWorker:reject', () => _supabase.hireAndReject(
            jobId: jobId,
            hiredWorkerProfileId: hiredWorkerProfileId,
            rejectApplicationIds: rejectAppIds,
          ));
    }

    _createConversation(jobId, hiredWorkerProfileId, employerProfileId,
        onConversationCreated);
  }

  Future<void> _createConversation(
    String jobId,
    String workerProfileId,
    String employerProfileId,
    void Function(Conversation)? onCreated,
  ) async {
    try {
      final conv = await _supabase.getOrCreateConversation(
        jobId: jobId,
        employerProfileId: employerProfileId,
        workerProfileId: workerProfileId,
      );
      onCreated?.call(conv);
    } catch (e) {
      debugPrint('Failed to create conversation: $e');
      _lastOperationError = 'Failed to create conversation';
      notifyListeners();
    }
  }

  void completeJob(String jobId) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId) return j.copyWith(status: JobStatus.completed);
      return j;
    }).toList();
    notifyListeners();
    _fireAndForget('completeJob',
        () => _supabase.updateJobStatus(jobId, status: 'completed'));
  }

  void _fireAndForget(String label, Future<dynamic> Function() task) {
    task().then((_) {}, onError: (e) {
      debugPrint('$label failed: $e');
      _lastOperationError = '$label failed';
      notifyListeners();
    });
  }

  void clear() {
    _jobs = [];
    _applications = [];
    _lastOperationError = null;
    notifyListeners();
  }
}
