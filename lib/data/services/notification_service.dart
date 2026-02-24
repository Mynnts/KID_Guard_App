import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/child_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of notifications for a user
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to prevent unbounded growth
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Add a new notification with category-based filtering and dedup
  Future<void> addNotification(
    String userId,
    NotificationModel notification,
  ) async {
    try {
      // 1. Check if notification category is enabled in user settings
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('notificationSettings')) {
          final settings = data['notificationSettings'] as Map<String, dynamic>;

          bool isEnabled = true;
          final category = notification.category;

          switch (category) {
            case 'app_blocked':
              isEnabled = settings['appBlocked'] ?? true;
              break;
            case 'time_limit':
              isEnabled = settings['timeLimit'] ?? true;
              break;
            case 'location':
              isEnabled = settings['location'] ?? true;
              break;
            case 'daily_report':
              isEnabled = settings['dailyReports'] ?? false;
              break;
            default:
              isEnabled = true; // system notifications always enabled
          }

          if (!isEnabled) {
            debugPrint(
              'Notification suppressed: category=$category is disabled.',
            );
            return;
          }
        }
      }

      // 2. Dedup: skip if same title+type exists within last 5 minutes
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final recentDups = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('title', isEqualTo: notification.title)
          .where('type', isEqualTo: notification.type)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();

      if (recentDups.docs.isNotEmpty) {
        debugPrint(
          'Notification deduped: "${notification.title}" already exists.',
        );
        return;
      }

      // 3. Add to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());

      // 4. Cleanup old notifications (keep max 50, delete > 30 days)
      _cleanupOldNotifications(userId);
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Cleanup: delete notifications older than 30 days
  Future<void> _cleanupOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (oldDocs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in oldDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Cleaned up ${oldDocs.docs.length} old notifications.');
      }
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  // Static lock to prevent concurrent seeding
  static bool _isSeeding = false;

  // Seed initial notifications if empty (for demo/reality check)
  Future<void> seedInitialNotifications(
    String userId,
    List<ChildModel> children, {
    bool force = false,
  }) async {
    // Prevent concurrent/duplicate seeding
    if (_isSeeding) return;
    _isSeeding = true;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .limit(1)
          .get();

      // Only seed if collection is truly empty (first time)
      if (snapshot.docs.isEmpty || force) {
        final batch = _firestore.batch();
        final collectionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications');

        // Add "Child Added" notifications for existing children
        for (var child in children) {
          final docRef = collectionRef.doc();
          final notification = {
            'title': 'Child Added',
            'message': '${child.name} has been added to the family group.',
            'timestamp': Timestamp.now(),
            'type': 'system',
            'category': 'system',
            'isRead': false,
            'iconName': 'person_add_rounded',
            'colorValue': Colors.blue.value,
          };
          batch.set(docRef, notification);
        }

        // Add a system welcome message if no children yet
        if (children.isEmpty) {
          final docRef = collectionRef.doc();
          final notification = {
            'title': 'Welcome to Kid Guard',
            'message': 'Get started by adding your child\'s profile.',
            'timestamp': Timestamp.now(),
            'type': 'system',
            'category': 'system',
            'isRead': false,
            'iconName': 'check_circle_rounded',
            'colorValue': Colors.green.value,
          };
          batch.set(docRef, notification);
        }

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error seeding notifications: $e');
    }
    // Keep _isSeeding = true so it never runs again in this app session
  }

  /// Remove duplicate notifications (same title + message within 1 minute)
  Future<void> removeDuplicateNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      final seen = <String>{};
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Create a key from title + message to identify duplicates
        final key = '${data['title']}|${data['message']}';
        if (seen.contains(key)) {
          batch.delete(doc.reference);
          deleteCount++;
        } else {
          seen.add(key);
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        debugPrint('Removed $deleteCount duplicate notifications.');
      }
    } catch (e) {
      debugPrint('Error removing duplicates: $e');
    }
  }
}
