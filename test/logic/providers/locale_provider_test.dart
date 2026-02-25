import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguard/logic/providers/locale_provider.dart';

void main() {
  group('LocaleProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default locale is Thai', () {
      final provider = LocaleProvider();
      expect(provider.locale, const Locale('th'));
      expect(provider.languageCode, 'th');
    });

    test('setLocale to English', () async {
      final provider = LocaleProvider();

      await provider.setLocale('en');

      expect(provider.locale, const Locale('en'));
      expect(provider.languageCode, 'en');
    });

    test('setLocale to Thai', () async {
      final provider = LocaleProvider();

      await provider.setLocale('en');
      await provider.setLocale('th');

      expect(provider.locale, const Locale('th'));
      expect(provider.languageCode, 'th');
    });

    test('persists locale to SharedPreferences', () async {
      final provider = LocaleProvider();

      await provider.setLocale('en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
    });

    test('loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});

      final provider = LocaleProvider();

      // Wait for _loadFromPrefs()
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.locale, const Locale('en'));
      expect(provider.languageCode, 'en');
    });

    test('notifies listeners on locale change', () async {
      final provider = LocaleProvider();
      int callCount = 0;
      provider.addListener(() => callCount++);

      await provider.setLocale('en');

      expect(callCount, greaterThanOrEqualTo(1));
    });
  });
}
