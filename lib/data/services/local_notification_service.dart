import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Standard app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check if notifications are enabled in local settings
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('notif_sound') ?? true;
    final vibrationEnabled = prefs.getBool('notif_vibration') ?? true;

    // Map title to category settings
    bool isEnabled = true;
    final lowTitle = title.toLowerCase();
    if (lowTitle.contains('blocked')) {
      isEnabled = prefs.getBool('notif_app_blocked') ?? true;
    } else if (lowTitle.contains('limit') || lowTitle.contains('time')) {
      isEnabled = prefs.getBool('notif_time_limit') ?? true;
    } else if (lowTitle.contains('location')) {
      isEnabled = prefs.getBool('notif_location') ?? true;
    }

    if (!isEnabled) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'kidguard_alerts',
          'Kid Guard Alerts',
          channelDescription: 'Alerts for child activity and protection status',
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
}
