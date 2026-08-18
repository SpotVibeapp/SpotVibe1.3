import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen app language.
///
/// `_locale == null` means "follow the device/system language". When set, it
/// overrides the device. Persisted in SharedPreferences so the choice sticks
/// across restarts. Registered in main.dart and consumed by the
/// MaterialApp.router (`locale:`).
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'spotvibe_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  /// Stable code for persistence: 'system' | 'en' | 'es'.
  String get currentCode {
    if (_locale == null) return 'system';
    if (_locale!.languageCode == 'es') return 'es';
    return 'en';
  }

  /// Loads the persisted choice. Call once at startup before the first build
  /// so the UI doesn't flash in the wrong language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = _fromCode(code);
    notifyListeners();
  }

  /// Sets the language and persists it. [code] is 'system' | 'en' | 'es'.
  Future<void> setCode(String code) async {
    _locale = _fromCode(code);
    final prefs = await SharedPreferences.getInstance();
    if (code == 'system') {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, code);
    }
    notifyListeners();
  }

  Locale? _fromCode(String? code) {
    switch (code) {
      case 'en':
        return const Locale('en');
      case 'es':
        return const Locale('es');
      default:
        return null; // system default
    }
  }
}
