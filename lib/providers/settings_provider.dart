import 'package:flutter/foundation.dart';
import '../utils/translations.dart';

class SettingsNotifier extends ChangeNotifier {
  LanguageOption _language = LanguageOption.en;

  LanguageOption get language => _language;

  void setLanguage(LanguageOption lang) {
    _language = lang;
    notifyListeners();
  }

  void clear() {
    _language = LanguageOption.en;
    notifyListeners();
  }
}
