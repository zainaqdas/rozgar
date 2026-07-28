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

  group('AuthNotifier loginWithPhoneOrEmail', () {
    test('sets authIdentity with phone number', () {
      notifier.loginWithPhoneOrEmail('+923001234567');
      expect(notifier.authIdentity, isNotNull);
      expect(notifier.authIdentity!.phoneNumber, '+923001234567');
      expect(notifier.authIdentity!.email, isNull);
    });

    test('sets authIdentity with email', () {
      notifier.loginWithPhoneOrEmail('test@example.com');
      expect(notifier.authIdentity, isNotNull);
      expect(notifier.authIdentity!.email, 'test@example.com');
      expect(notifier.authIdentity!.phoneNumber, isNull);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);
      notifier.loginWithPhoneOrEmail('+923001234567');
      expect(notifyCount, 1);
    });
  });

  group('AuthNotifier verifyOtp', () {
    test('always returns true (mock)', () {
      expect(notifier.verifyOtp('123456'), isTrue);
      expect(notifier.verifyOtp(''), isTrue);
    });
  });

  group('AuthNotifier clearOperationError', () {
    test('clears error and notifies', () {
      notifier.clearOperationError();
      expect(notifier.lastOperationError, isNull);
    });
  });

  group('AuthNotifier logout', () {
    test('clears authIdentity and needsOnboarding', () async {
      notifier.loginWithPhoneOrEmail('+923001234567');
      expect(notifier.authIdentity, isNotNull);

      await notifier.logout();
      expect(notifier.authIdentity, isNull);
      expect(notifier.needsOnboarding, isFalse);
    });
  });
}
