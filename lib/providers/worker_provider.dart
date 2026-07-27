import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

class WorkerNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<WorkerEntry> _cachedWorkers = [];
  String? _lastOperationError;

  List<WorkerEntry> get allWorkers => List.unmodifiable(_cachedWorkers);
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  Future<void> loadAllWorkers() async {
    try {
      final workers = await _supabase.getAllWorkers();
      _cachedWorkers = workers
          .map((w) => WorkerEntry(profile: w.profile, details: w.details))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load workers: $e');
      _lastOperationError = 'Failed to load workers';
      notifyListeners();
    }
  }

  void setWorkers(List<WorkerEntry> workers) {
    _cachedWorkers = workers;
    notifyListeners();
  }

  ({Profile profile, WorkerDetails? workerDetails})? getPublicProfile(
    String profileId,
    Profile? selfWorkerProfile,
    WorkerDetails? selfWorkerDetails,
  ) {
    if (profileId == selfWorkerProfile?.id) {
      return (profile: selfWorkerProfile!, workerDetails: selfWorkerDetails);
    }
    final cached =
        _cachedWorkers.where((w) => w.profile.id == profileId).firstOrNull;
    if (cached != null) {
      return (profile: cached.profile, workerDetails: cached.details);
    }
    return null;
  }

  void clear() {
    _cachedWorkers = [];
    _lastOperationError = null;
    notifyListeners();
  }
}
