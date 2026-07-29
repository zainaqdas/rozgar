import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';

const _languageKey = 'rozgar_language';

class SettingsNotifier extends ChangeNotifier {
  LanguageOption _language = LanguageOption.en;

  LanguageOption get language => _language;

  /// Load persisted language preference from SharedPreferences.
  /// Call once during app initialization (e.g. Coordinator.initialize).
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_languageKey);
      if (saved == 'ur') {
        _language = LanguageOption.ur;
      } else {
        _language = LanguageOption.en;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load language preference: $e');
    }
  }

  void setLanguage(LanguageOption lang) {
    _language = lang;
    notifyListeners();
    _persistLanguage(lang);
  }

  Future<void> _persistLanguage(LanguageOption lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, lang.name);
    } catch (e) {
      debugPrint('Failed to persist language preference: $e');
    }
  }

  void clear() {
    _language = LanguageOption.en;
    notifyListeners();
  }
}
