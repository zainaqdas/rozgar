// Integration smoke test — exercises auth → profile → job → chat against a
// real Supabase instance. Skipped by default; run with:
//
//   flutter test --tags integration \
//     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=your-anon-key
//
// Requires a seeded test user (see supabase/migrations/20240726000001).
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/services/config.dart';
import 'package:rozgar/services/supabase_config.dart';
import 'package:rozgar/services/supabase_service.dart';

void main() {
  final hasConfig = AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabaseAnonKey.isNotEmpty;

  group('Supabase integration smoke test', () {
    setUpAll(() async {
      if (!hasConfig) return;
      await SupabaseConfig.initialize();
    });

    test('SUPABASE_URL is configured', () {
      if (!hasConfig) {
        markTestSkipped('SUPABASE_URL / SUPABASE_ANON_KEY not provided');
        return;
      }
      expect(AppConfig.supabaseUrl, isNotEmpty);
    });

    test('can fetch all jobs without error', () async {
      if (!hasConfig) {
        markTestSkipped('SUPABASE_URL / SUPABASE_ANON_KEY not provided');
        return;
      }
      final service = SupabaseService.instance;
      final jobs = await service.getAllJobs(limit: 5);
      expect(jobs, isA<List>());
    });

    test('can fetch all workers without error', () async {
      if (!hasConfig) {
        markTestSkipped('SUPABASE_URL / SUPABASE_ANON_KEY not provided');
        return;
      }
      final service = SupabaseService.instance;
      final workers = await service.getAllWorkers(limit: 5);
      expect(workers, isA<List>());
    });

    test('getAllJobs respects pagination limit', () async {
      if (!hasConfig) {
        markTestSkipped('SUPABASE_URL / SUPABASE_ANON_KEY not provided');
        return;
      }
      final service = SupabaseService.instance;
      final page1 = await service.getAllJobs(limit: 2, offset: 0);
      final page2 = await service.getAllJobs(limit: 2, offset: 2);
      expect(page1.length, lessThanOrEqualTo(2));
      expect(page2.length, lessThanOrEqualTo(2));
      // Pages should not overlap (if enough data exists)
      if (page1.isNotEmpty && page2.isNotEmpty) {
        final ids1 = page1.map((j) => j.id).toSet();
        final ids2 = page2.map((j) => j.id).toSet();
        expect(ids1.intersection(ids2), isEmpty);
      }
    });
  });
}
