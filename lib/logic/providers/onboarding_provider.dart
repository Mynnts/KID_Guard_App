// ==================== Onboarding Provider ====================
/// จัดการสถานะ onboarding: เคยดูหรือยัง (SharedPreferences)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _key = 'hasSeenOnboarding';

  bool _hasSeenOnboarding = false;
  bool _isLoaded = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoaded => _isLoaded;

  /// โหลดสถานะจาก SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_key) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  /// จบ onboarding → บันทึกว่าเคยดูแล้ว
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  /// reset สำหรับดูซ้ำจาก Settings
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    _hasSeenOnboarding = false;
    notifyListeners();
  }
}
