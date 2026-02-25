import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguard/logic/providers/onboarding_provider.dart';

void main() {
  group('OnboardingProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default state is not seen and not loaded', () {
      final provider = OnboardingProvider();
      expect(provider.hasSeenOnboarding, isFalse);
      expect(provider.isLoaded, isFalse);
    });

    test('init loads default false from prefs', () async {
      final provider = OnboardingProvider();

      await provider.init();

      expect(provider.hasSeenOnboarding, isFalse);
      expect(provider.isLoaded, isTrue);
    });

    test('init loads saved true from prefs', () async {
      SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});

      final provider = OnboardingProvider();
      await provider.init();

      expect(provider.hasSeenOnboarding, isTrue);
      expect(provider.isLoaded, isTrue);
    });

    test('completeOnboarding sets to true', () async {
      final provider = OnboardingProvider();
      await provider.init();
      expect(provider.hasSeenOnboarding, isFalse);

      await provider.completeOnboarding();

      expect(provider.hasSeenOnboarding, isTrue);

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenOnboarding'), isTrue);
    });

    test('resetOnboarding sets back to false', () async {
      final provider = OnboardingProvider();
      await provider.init();
      await provider.completeOnboarding();
      expect(provider.hasSeenOnboarding, isTrue);

      await provider.resetOnboarding();

      expect(provider.hasSeenOnboarding, isFalse);

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenOnboarding'), isFalse);
    });

    test('notifies listeners on init', () async {
      final provider = OnboardingProvider();
      int callCount = 0;
      provider.addListener(() => callCount++);

      await provider.init();

      expect(callCount, greaterThanOrEqualTo(1));
    });

    test('notifies listeners on completeOnboarding', () async {
      final provider = OnboardingProvider();
      await provider.init();

      int callCount = 0;
      provider.addListener(() => callCount++);

      await provider.completeOnboarding();

      expect(callCount, greaterThanOrEqualTo(1));
    });

    test('notifies listeners on resetOnboarding', () async {
      final provider = OnboardingProvider();
      await provider.init();
      await provider.completeOnboarding();

      int callCount = 0;
      provider.addListener(() => callCount++);

      await provider.resetOnboarding();

      expect(callCount, greaterThanOrEqualTo(1));
    });
  });
}
