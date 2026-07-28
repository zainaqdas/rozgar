import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rozgar/providers/providers.dart';

void main() {
  test('domain providers initialize with correct defaults', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Auth
    expect(container.read(authProvider).authIdentity, isNull);
    expect(container.read(authProvider).needsOnboarding, isFalse);

    // Profile
    expect(container.read(profileProvider).employerProfile, isNull);
    expect(container.read(profileProvider).workerProfile, isNull);
    expect(container.read(profileProvider).activeProfile, isNull);
    expect(container.read(profileProvider).reviews, isEmpty);

    // Jobs
    expect(container.read(jobProvider).jobs, isEmpty);
    expect(container.read(jobProvider).applications, isEmpty);

    // Chat
    expect(container.read(chatProvider).conversations, isEmpty);
    expect(container.read(chatProvider).messages, isEmpty);

    // Notifications
    expect(container.read(notificationProvider).notifications, isEmpty);

    // Workers
    expect(container.read(workerProvider).allWorkers, isEmpty);
  });
}
