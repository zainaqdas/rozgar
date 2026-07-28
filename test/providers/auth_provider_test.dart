import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/auth_provider.dart';

void main() {
  late AuthNotifier notifier;

  setUp(() {
    notifier = AuthNotifier();
  });

  group('AuthNotifier initial state', () {
    test('authIdentity is null', () {
      expect(notifier.authIdentity, isNull);
    });

    test('needsOnboarding is false', () {
      expect(notifier.needsOnboarding, isFalse);
    });

    test('lastOperationError is null', () {
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('AuthNotifier clearOperationError', () {
    test('clears error and notifies', () {
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.clearOperationError();
      expect(notifier.lastOperationError, isNull);
      expect(notified, true);
    });
  });

  group('AuthNotifier logout', () {
    test('clears authIdentity and needsOnboarding', () async {
      // Without Supabase, logout still clears local state gracefully
      await notifier.logout();
      expect(notifier.authIdentity, isNull);
      expect(notifier.needsOnboarding, isFalse);
    });

    test('notifies listeners after logout', () async {
      var notified = false;
      notifier.addListener(() => notified = true);
      await notifier.logout();
      expect(notified, true);
    });
  });

  group('AuthNotifier phone OTP methods exist', () {
    test('sendPhoneOtp returns error when Supabase unavailable', () async {
      // Without Supabase initialized, this should return an error string
      final error = await notifier.sendPhoneOtp('+923001234567');
      expect(error, isNotNull);
    });

    test('verifyPhoneOtp returns error when Supabase unavailable', () async {
      final error = await notifier.verifyPhoneOtp('+923001234567', '123456');
      expect(error, isNotNull);
    });
  });
}
