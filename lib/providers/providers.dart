import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'job_provider.dart';
import 'chat_provider.dart';
import 'notification_provider.dart';
import 'worker_provider.dart';
import 'settings_provider.dart';

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  return AppState();
});

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier();
});

final profileProvider = ChangeNotifierProvider<ProfileNotifier>((ref) {
  return ProfileNotifier();
});

final jobProvider = ChangeNotifierProvider<JobNotifier>((ref) {
  return JobNotifier();
});

final chatProvider = ChangeNotifierProvider<ChatNotifier>((ref) {
  return ChatNotifier();
});

final notificationProvider = ChangeNotifierProvider<NotificationNotifier>((ref) {
  return NotificationNotifier();
});

final workerProvider = ChangeNotifierProvider<WorkerNotifier>((ref) {
  return WorkerNotifier();
});

final settingsProvider = ChangeNotifierProvider<SettingsNotifier>((ref) {
  return SettingsNotifier();
});
