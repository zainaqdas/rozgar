import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/providers/settings_provider.dart';
import 'package:rozgar/utils/translations.dart';

void main() {
  late SettingsNotifier notifier;

  setUp(() {
    notifier = SettingsNotifier();
  });

  group('SettingsNotifier initial state', () {
    test('defaults to English', () {
      expect(notifier.language, LanguageOption.en);
    });
  });

  group('SettingsNotifier setLanguage', () {
    test('switches to Urdu', () {
      notifier.setLanguage(LanguageOption.ur);
      expect(notifier.language, LanguageOption.ur);
    });

    test('switches back to English', () {
      notifier.setLanguage(LanguageOption.ur);
      notifier.setLanguage(LanguageOption.en);
      expect(notifier.language, LanguageOption.en);
    });

    test('notifies listeners on change', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);
      notifier.setLanguage(LanguageOption.ur);
      expect(notifyCount, 1);
    });
  });

  group('SettingsNotifier clear', () {
    test('resets language to English', () {
      notifier.setLanguage(LanguageOption.ur);
      notifier.clear();
      expect(notifier.language, LanguageOption.en);
    });
  });
}
