import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_language';

  Locale _locale = const Locale('th');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadFromPrefs();
  }

  /// Initialize and load from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_key) ?? 'th';
    _locale = Locale(savedLang);
    notifyListeners();
  }

  /// Set locale and save to SharedPreferences
  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }

  /// Get current language code
  String get languageCode => _locale.languageCode;
}
