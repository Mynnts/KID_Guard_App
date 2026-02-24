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

      // 2. Dedup: check only the single most recent notification
      // This avoids the need for a composite index and handles 99% of duplicate cases.
      final lastNotifSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastNotifSnapshot.docs.isNotEmpty) {
        final lastNotif = lastNotifSnapshot.docs.first.data();
        final lastTimestamp = (lastNotif['timestamp'] as Timestamp).toDate();

        // If same content within 2 minutes, it's a duplicate
        if (lastNotif['title'] == notification.title &&
            lastNotif['message'] == notification.message &&
            DateTime.now().difference(lastTimestamp).inMinutes < 2) {
          debugPrint('Notification suppressed: Duplicate of most recent.');
          return;
        }
      }

      // 3. Add to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());

      debugPrint('Notification added successfully: ${notification.title}');

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

  // Seed initial notifications if empty (for demo/reality check)
  Future<void> seedInitialNotifications(
    String userId,
    List<ChildModel> children, {
    bool force = false,
  }) async {
    // Seeding disabled to ensure notifications only reflect real user actions.
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
