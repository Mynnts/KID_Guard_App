import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_info_model.dart';

class AppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const platform = MethodChannel('com.kidguard/native');

  Future<List<AppInfoModel>> fetchInstalledApps() async {
    try {
      // 1. Get all installed apps with icons from the plugin
      List<AppInfo> allApps = await InstalledApps.getInstalledApps(
        withIcon: true,
      );

      // 2. Get list of launcher apps (user-facing) and system status from Native
      final List<dynamic> launcherAppsData = await platform.invokeMethod(
        'getLauncherApps',
      );

      // Create a map for quick lookup of system status by package name
      final Map<String, bool> systemAppMap = {};
      for (var data in launcherAppsData) {
        if (data is Map) {
          systemAppMap[data['packageName']] = data['isSystem'] ?? false;
        }
      }

      // 3. Filter and Map
      List<AppInfoModel> filteredApps = [];

      for (var app in allApps) {
        if (systemAppMap.containsKey(app.packageName)) {
          String? iconBase64;
          if (app.icon != null) {
            iconBase64 = base64Encode(app.icon!);
          }

          filteredApps.add(
            AppInfoModel(
              packageName: app.packageName,
              name: app.name,
              isSystemApp: systemAppMap[app.packageName] ?? false,
              isLocked: false,
              iconBase64: iconBase64,
            ),
          );
        }
      }

      return filteredApps;
    } catch (e) {
      print("Error fetching apps: $e");
      return [];
    }
  }

  Future<void> syncApps(String parentUid, String childId) async {
    try {
      final apps = await fetchInstalledApps();
      print('Syncing ${apps.length} apps for child $childId');

      final collectionRef = _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('apps');

      var batch = _firestore.batch();
      int count = 0;

      for (var app in apps) {
        // Sanitize package name for use as document ID
        final docId = app.packageName.replaceAll('.', '_');
        final docRef = collectionRef.doc(docId);

        final data = {
          'packageName': app.packageName,
          'name': app.name,
          'isSystemApp': app.isSystemApp,
          'iconBase64': app.iconBase64,
          // We do NOT overwrite isLocked to preserve parent's setting
        };

        batch.set(docRef, data, SetOptions(merge: true));

        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      // Commit remaining
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error syncing apps: $e');
    }
  }

  Stream<List<AppInfoModel>> streamApps(String parentUid, String childId) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('apps')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppInfoModel.fromMap(doc.data());
          }).toList();
        });
  }

  Future<void> toggleAppLock(
    String parentUid,
    String childId,
    String packageName,
    bool isLocked,
  ) async {
    // Ensure document ID matches the one created in syncApps (dots replaced by underscores)
    final docId = packageName.replaceAll('.', '_');

    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('apps')
        .doc(docId)
        .set({'isLocked': isLocked}, SetOptions(merge: true));
  }

  /// Request child device to sync apps (called from parent)
  Future<void> requestSync(String parentUid, String childId) async {
    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .set({'syncRequested': true}, SetOptions(merge: true));
  }

  /// Clear sync request flag (called from child after syncing)
  Future<void> clearSyncRequest(String parentUid, String childId) async {
    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .set({'syncRequested': false}, SetOptions(merge: true));
  }

  /// Stream to listen for sync requests (called from child)
  Stream<bool> streamSyncRequest(String parentUid, String childId) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data()?['syncRequested'] ?? false;
          }
          return false;
        });
  }
}
