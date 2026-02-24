import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );
  }

  /// Show a local notification with category-based filtering.
  ///
  /// [category] determines the notification channel and settings filter.
  /// Valid categories: 'app_blocked', 'time_limit', 'location', 'daily_report', 'system'
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String category = 'system',
  }) async {
    // Check if this category is enabled in local settings
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('notif_sound') ?? true;
    final vibrationEnabled = prefs.getBool('notif_vibration') ?? true;

    bool isEnabled = true;
    switch (category) {
      case 'app_blocked':
        isEnabled = prefs.getBool('notif_app_blocked') ?? true;
        break;
      case 'time_limit':
        isEnabled = prefs.getBool('notif_time_limit') ?? true;
        break;
      case 'location':
        isEnabled = prefs.getBool('notif_location') ?? true;
        break;
      case 'daily_report':
        isEnabled = prefs.getBool('notif_daily_reports') ?? false;
        break;
      default:
        isEnabled = true; // system always enabled
    }

    if (!isEnabled) return;

    // Select channel based on category for granular Android notification control
    final channelInfo = _getChannelForCategory(category);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelInfo['id']!,
          channelInfo['name']!,
          channelDescription: channelInfo['description']!,
          importance: Importance.max,
          priority: Priority.high,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          color: const Color(0xFF6B9080),
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Returns channel info based on notification category
  static Map<String, String> _getChannelForCategory(String category) {
    switch (category) {
      case 'app_blocked':
        return {
          'id': 'kidguard_app_blocked',
          'name': 'App Blocked Alerts',
          'description': 'Alerts when a child tries to open a blocked app',
        };
      case 'time_limit':
        return {
          'id': 'kidguard_time_limit',
          'name': 'Time Limit Alerts',
          'description': 'Alerts about screen time limits',
        };
      case 'location':
        return {
          'id': 'kidguard_location',
          'name': 'Location Alerts',
          'description': 'Alerts about child location changes',
        };
      case 'daily_report':
        return {
          'id': 'kidguard_daily_report',
          'name': 'Daily Reports',
          'description': 'Daily usage summary reports',
        };
      default:
        return {
          'id': 'kidguard_system',
          'name': 'Kid Guard System',
          'description': 'System and account notifications',
        };
    }
  }
}
