import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/auth_identity.dart';

void main() {
  group('AuthIdentity', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final identity = AuthIdentity(
        id: 'auth-1',
        phoneNumber: '+92 300 1234567',
        email: 'test@rozgar.pk',
        preferredLanguage: PreferredLanguage.en,
        createdAt: now,
      );

      final json = identity.toJson();
      final restored = AuthIdentity.fromJson(json);

      expect(restored.id, identity.id);
      expect(restored.phoneNumber, identity.phoneNumber);
      expect(restored.email, identity.email);
      expect(restored.preferredLanguage, identity.preferredLanguage);
      expect(restored.createdAt.toIso8601String(), now.toIso8601String());
    });

    test('supports Urdu preferred language', () {
      final identity = AuthIdentity(
        id: 'auth-2',
        preferredLanguage: PreferredLanguage.ur,
        createdAt: DateTime.now(),
      );
      expect(identity.preferredLanguage, PreferredLanguage.ur);
      expect(identity.toJson()['preferred_language'], 'ur');
    });

    test('defaults to English language', () {
      final identity = AuthIdentity(
        id: 'auth-3',
        createdAt: DateTime.now(),
      );
      expect(identity.preferredLanguage, PreferredLanguage.en);
    });

    test('all fields are nullable except id and createdAt', () {
      final identity = AuthIdentity(
        id: 'auth-4',
        createdAt: DateTime.now(),
      );
      expect(identity.phoneNumber, isNull);
      expect(identity.email, isNull);
    });

    test('fromJson handles null created_at without throwing', () {
      final identity = AuthIdentity.fromJson({
        'id': 'auth-2',
        'created_at': null,
      });
      expect(identity.id, 'auth-2');
      expect(identity.createdAt, isA<DateTime>());
    });

    test('fromJson handles malformed created_at without throwing', () {
      final identity = AuthIdentity.fromJson({
        'id': 'auth-3',
        'created_at': 'not-a-date',
      });
      expect(identity.id, 'auth-3');
      expect(identity.createdAt, isA<DateTime>());
    });
  });
}
