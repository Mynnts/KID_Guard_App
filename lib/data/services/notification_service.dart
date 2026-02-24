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
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Add a new notification
  Future<void> addNotification(
    String userId,
    NotificationModel notification,
  ) async {
    try {
      // 1. Check if notification type is enabled in user settings
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('notificationSettings')) {
          final settings = data['notificationSettings'] as Map<String, dynamic>;

          bool isEnabled = true;
          final title = notification.title.toLowerCase();

          if (title.contains('blocked')) {
            isEnabled = settings['appBlocked'] ?? true;
          } else if (title.contains('limit') || title.contains('time')) {
            isEnabled = settings['timeLimit'] ?? true;
          } else if (title.contains('location')) {
            isEnabled = settings['location'] ?? true;
          } else if (notification.type == 'system' &&
              title.contains('report')) {
            isEnabled = settings['dailyReports'] ?? false;
          }

          if (!isEnabled) {
            debugPrint(
              'Notification suppressed: ${notification.title} is disabled in settings.',
            );
            return;
          }
        }
      }

      // 2. Add to Firestore if enabled
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());
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

  // Seed initial notifications if empty (for demo/reality check)
  Future<void> seedInitialNotifications(
    String userId,
    List<ChildModel> children, {
    bool force = false,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .limit(1)
        .get();

    // Check if notifications exist
    if (snapshot.docs.isEmpty || force) {
      final batch = _firestore.batch();
      final collectionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      // Add "Child Added" notifications for existing children
      for (var child in children) {
        // Create doc ref
        final docRef = collectionRef.doc();

        // Create notification
        final notification = {
          'title': 'Child Added',
          'message': '${child.name} has been added to the family group.',
          'timestamp': Timestamp.now(), // Or backdate slightly
          'type': 'system',
          'isRead': false,
          'iconName': 'person_add_rounded',
          'colorValue': Colors.blue.value,
        };

        batch.set(docRef, notification);
      }

      // Add a system welcome message if no children yet?
      if (children.isEmpty) {
        final docRef = collectionRef.doc();
        final notification = {
          'title': 'Welcome to Kid Guard',
          'message': 'Get started by adding your child\'s profile.',
          'timestamp': Timestamp.now(),
          'type': 'system',
          'isRead': false,
          'iconName': 'check_circle_rounded',
          'colorValue': Colors.green.value,
        };
        batch.set(docRef, notification);
      }

      await batch.commit();
    }
  }
}
