import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'app_theme';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  /// Initialize and load from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_key) ?? 'system';
    _themeMode = _stringToThemeMode(savedTheme);
    notifyListeners();
  }

  /// Set theme mode and save to SharedPreferences
  Future<void> setThemeMode(String themeString) async {
    _themeMode = _stringToThemeMode(themeString);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeString);
  }

  /// Get current theme as string for UI
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
