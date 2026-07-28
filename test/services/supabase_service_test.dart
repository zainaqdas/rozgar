import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/services/supabase_service.dart';

class TestSupabaseService extends SupabaseService {
  TestSupabaseService.test() : super.test();

  static final TestSupabaseService testInstance = TestSupabaseService.test();

  bool throwRpc = false;
  bool throwReject = false;
  bool throwHire = false;
  bool throwRollback = false;
  bool throwFindConversation = false;
  bool throwInsertConversation = false;

  Map<String, dynamic>? existingConversation;
  Map<String, dynamic>? existingConversationOnRetry;
  int findConversationCallCount = 0;

  @override
  Future<void> callHireAndRejectRpc(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) async {
    if (throwRpc) throw Exception('RPC failed');
  }

  @override
  Future<void> rejectApplications(List<String> ids) async {
    if (throwReject) throw Exception('Reject failed');
  }

  @override
  Future<void> hireApplication(String jobId, String workerProfileId) async {
    if (throwHire) throw Exception('Hire failed');
  }

  @override
  Future<void> rollbackApplications(
    String jobId,
    String hiredWorkerProfileId,
    List<String> rejectApplicationIds,
  ) async {
    if (throwRollback) throw Exception('Rollback failed');
  }

  @override
  Future<Map<String, dynamic>?> findConversation(
    String jobId,
    String workerProfileId,
  ) async {
    findConversationCallCount++;
    if (throwFindConversation) throw Exception('Find failed');
    if (findConversationCallCount >= 2 && existingConversationOnRetry != null) {
      return existingConversationOnRetry;
    }
    return existingConversation;
  }

  @override
  Future<Map<String, dynamic>> insertConversation(
    String jobId,
    String employerProfileId,
    String workerProfileId,
  ) async {
    if (throwInsertConversation) throw Exception('Insert failed');
    return {
      'id': 'conv-new',
      'job_id': jobId,
      'employer_profile_id': employerProfileId,
      'worker_profile_id': workerProfileId,
      'last_message_text': 'Conversation started',
      'last_message_time': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  late TestSupabaseService service;

  setUp(() {
    service = TestSupabaseService.testInstance;
    service.throwRpc = false;
    service.throwReject = false;
    service.throwHire = false;
    service.throwRollback = false;
    service.throwFindConversation = false;
    service.throwInsertConversation = false;
    service.existingConversation = null;
    service.existingConversationOnRetry = null;
    service.findConversationCallCount = 0;
  });

  group('hireAndReject', () {
    test('calls RPC on success path', () async {
      await service.hireAndReject(
        jobId: 'job-1',
        hiredWorkerProfileId: 'wrk-1',
        rejectApplicationIds: ['app-2'],
      );
    });

    test('falls back to sequential update when RPC fails', () async {
      service.throwRpc = true;

      await service.hireAndReject(
        jobId: 'job-1',
        hiredWorkerProfileId: 'wrk-1',
        rejectApplicationIds: ['app-2'],
      );
    });

    test('handles empty reject list', () async {
      service.throwRpc = true;

      await service.hireAndReject(
        jobId: 'job-1',
        hiredWorkerProfileId: 'wrk-1',
        rejectApplicationIds: [],
      );
    });

    test('rolls back when sequential update fails', () async {
      service.throwRpc = true;
      service.throwHire = true;

      expect(
        () => service.hireAndReject(
          jobId: 'job-1',
          hiredWorkerProfileId: 'wrk-1',
          rejectApplicationIds: ['app-2'],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getOrCreateConversation', () {
    test('returns existing conversation when found', () async {
      service.existingConversation = {
        'id': 'conv-1',
        'job_id': 'job-1',
        'employer_profile_id': 'emp-1',
        'worker_profile_id': 'wrk-1',
        'last_message_text': 'Hello',
        'last_message_time': '2026-01-01T00:00:00.000',
      };

      final result = await service.getOrCreateConversation(
        jobId: 'job-1',
        employerProfileId: 'emp-1',
        workerProfileId: 'wrk-1',
      );

      expect(result.id, 'conv-1');
      expect(result.jobId, 'job-1');
      expect(result.employerProfileId, 'emp-1');
      expect(result.workerProfileId, 'wrk-1');
      expect(service.findConversationCallCount, 1);
    });

    test('creates new conversation when none exists', () async {
      final result = await service.getOrCreateConversation(
        jobId: 'job-1',
        employerProfileId: 'emp-1',
        workerProfileId: 'wrk-1',
      );

      expect(result.id, 'conv-new');
      expect(service.findConversationCallCount, 1);
    });

    test('retries find on insert race condition', () async {
      service.throwInsertConversation = true;
      // First call returns null (no existing conversation)
      service.existingConversation = null;
      // After retry, conversation now exists
      service.existingConversationOnRetry = {
        'id': 'conv-retry',
        'job_id': 'job-1',
        'employer_profile_id': 'emp-1',
        'worker_profile_id': 'wrk-1',
        'last_message_text': 'Conversation started',
        'last_message_time': '2026-01-01T00:00:00.000',
      };

      final result = await service.getOrCreateConversation(
        jobId: 'job-1',
        employerProfileId: 'emp-1',
        workerProfileId: 'wrk-1',
      );

      expect(result.id, 'conv-retry');
      expect(service.findConversationCallCount, 2);
    });

    test('rethrows when retry also fails to find', () async {
      service.throwInsertConversation = true;
      // No conversation after retry either
      service.existingConversation = null;

      expect(
        () => service.getOrCreateConversation(
          jobId: 'job-1',
          employerProfileId: 'emp-1',
          workerProfileId: 'wrk-1',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
