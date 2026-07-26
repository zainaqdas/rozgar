import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/utils/translations.dart';

void main() {
  group('AppTranslations', () {
    test('returns English translation for key', () {
      expect(AppTranslations.t('appName', LanguageOption.en), 'Rozgar');
      expect(AppTranslations.t('employer', LanguageOption.en), 'Employer');
      expect(AppTranslations.t('worker', LanguageOption.en), 'Worker');
    });

    test('returns Urdu translation for key', () {
      expect(AppTranslations.t('appName', LanguageOption.ur), 'روزگار');
      expect(AppTranslations.t('employer', LanguageOption.ur), 'کام دینے والا (مالک)');
      expect(AppTranslations.t('worker', LanguageOption.ur), 'کام کرنے والا (کاریگر)');
    });

    test('falls back to English key if translation missing', () {
      expect(AppTranslations.t('nonexistent_key', LanguageOption.en), 'nonexistent_key');
    });

    test('returns all major UI keys in both languages', () {
      final keys = [
        'home', 'postJob', 'messages', 'profile', 'earnings', 'map',
        'chat', 'notifications', 'settings', 'budget', 'location',
        'description', 'cancel', 'submit', 'confirm', 'back', 'next',
        'category', 'urgency', 'rating', 'reviews', 'send', 'hire',
      ];

      for (final key in keys) {
        final en = AppTranslations.t(key, LanguageOption.en);
        final ur = AppTranslations.t(key, LanguageOption.ur);
        expect(en, isNotEmpty, reason: 'English key "$key" is empty');
        expect(ur, isNotEmpty, reason: 'Urdu key "$key" is empty');
        expect(en, isNot(equals(ur)), reason: 'English and Urdu should differ for "$key"');
      }
    });
  });
}
