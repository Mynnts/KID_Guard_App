import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguard/logic/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('default theme is system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
    });

    test('setThemeMode to light', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode('light');

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.themeModeString, 'light');
    });

    test('setThemeMode to dark', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode('dark');

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.themeModeString, 'dark');
    });

    test('setThemeMode to system', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode('dark');
      await provider.setThemeMode('system');

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.themeModeString, 'system');
    });

    test('unknown theme string defaults to system', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode('unknown_mode');

      expect(provider.themeMode, ThemeMode.system);
    });

    test('persists theme to SharedPreferences', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode('dark');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme'), 'dark');
    });

    test('loads saved theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'light'});

      final provider = ThemeProvider();

      // Wait for _loadFromPrefs() to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.themeMode, ThemeMode.light);
    });

    group('themeModeString getter', () {
      test('returns light for ThemeMode.light', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode('light');
        expect(provider.themeModeString, 'light');
      });

      test('returns dark for ThemeMode.dark', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode('dark');
        expect(provider.themeModeString, 'dark');
      });

      test('returns system for ThemeMode.system', () {
        final provider = ThemeProvider();
        expect(provider.themeModeString, 'system');
      });
    });

    test('notifies listeners on theme change', () async {
      final provider = ThemeProvider();
      int callCount = 0;
      provider.addListener(() => callCount++);

      await provider.setThemeMode('dark');

      expect(callCount, greaterThanOrEqualTo(1));
    });
  });
}
