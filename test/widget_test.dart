import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/app_state.dart';

void main() {
  test('AppState initial state is correct', () {
    final appState = AppState();
    expect(appState.authIdentity, isNull);
    expect(appState.employerProfile, isNull);
    expect(appState.workerProfile, isNull);
    expect(appState.activeProfile, isNull);
    expect(appState.jobs, isEmpty);
    expect(appState.applications, isEmpty);
    expect(appState.conversations, isEmpty);
    expect(appState.messages, isEmpty);
    expect(appState.reviews, isEmpty);
    appState.dispose();
  });
}
