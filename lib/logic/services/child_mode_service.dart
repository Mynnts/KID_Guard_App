import 'package:flutter/services.dart';

/// Service wrapper for Android ChildModeService
/// Manages persistent foreground notification for child mode
class ChildModeService {
  static const _channel = MethodChannel('com.kidguard/childmode');

  /// Start the foreground service with child info
  static Future<bool> start({
    required String childName,
    required int screenTime,
    required int dailyLimit,
  }) async {
    try {
      final result = await _channel.invokeMethod('startService', {
        'childName': childName,
        'screenTime': screenTime,
        'dailyLimit': dailyLimit,
      });
      return result == true;
    } catch (e) {
      print('ChildModeService.start error: $e');
      return false;
    }
  }

  /// Stop the foreground service
  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod('stopService');
      return result == true;
    } catch (e) {
      print('ChildModeService.stop error: $e');
      return false;
    }
  }

  /// Update notification with new screen time values
  static Future<bool> update({
    required String childName,
    required int screenTime,
    required int dailyLimit,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateService', {
        'childName': childName,
        'screenTime': screenTime,
        'dailyLimit': dailyLimit,
      });
      return result == true;
    } catch (e) {
      print('ChildModeService.update error: $e');
      return false;
    }
  }

  /// Check if service is currently running
  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod('isServiceRunning');
      return result == true;
    } catch (e) {
      print('ChildModeService.isRunning error: $e');
      return false;
    }
  }

  /// Set allow shutdown flag (call with true before stop() when PIN verified)
  /// When true: swiping app away will NOT relaunch it
  /// When false: swiping app away will auto-relaunch (child mode protection)
  static Future<bool> setAllowShutdown(bool allow) async {
    try {
      await _channel.invokeMethod('setAllowShutdown', {'allow': allow});
      return true;
    } catch (e) {
      print('ChildModeService.setAllowShutdown error: $e');
      return false;
    }
  }

  /// Get launch action from notification click
  /// Returns "com.kidguard.ACTION_STOP_CHILD_MODE" if user clicked stop button
  static Future<String?> getLaunchAction() async {
    try {
      final result = await _channel.invokeMethod('getLaunchAction');
      return result as String?;
    } catch (e) {
      print('ChildModeService.getLaunchAction error: $e');
      return null;
    }
  }
}
