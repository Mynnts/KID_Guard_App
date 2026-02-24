import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'system', 'child_activity', 'alert'
  final String
  category; // 'app_blocked', 'time_limit', 'location', 'daily_report', 'system'
  final bool isRead;
  final String? iconName;
  final int? colorValue;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.category = 'system',
    this.isRead = false,
    this.iconName,
    this.colorValue,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] ?? 'system',
      category: map['category'] ?? 'system',
      isRead: map['isRead'] ?? false,
      iconName: map['iconName'],
      colorValue: map['colorValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'category': category,
      'isRead': isRead,
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }

  // Helper to get IconData from string name
  IconData get icon {
    switch (iconName) {
      case 'person_add_rounded':
        return Icons.person_add_rounded;
      case 'settings_rounded':
        return Icons.settings_rounded;
      case 'warning_rounded':
        return Icons.warning_rounded;
      case 'check_circle_rounded':
        return Icons.check_circle_rounded;
      case 'edit_rounded':
        return Icons.edit_rounded;
      case 'vpn_key_rounded':
        return Icons.vpn_key_rounded;
      case 'schedule_rounded':
        return Icons.schedule_rounded;
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      case 'block_rounded':
        return Icons.block_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Helper to get Color
  Color get color {
    if (colorValue != null) {
      return Color(colorValue!);
    }
    switch (type) {
      case 'alert':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
