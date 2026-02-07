// ==================== นำเข้า Packages ====================
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_info_model.dart';
import 'device_service.dart';

// ==================== AppService ====================
/// บริการจัดการแอพที่ติดตั้งในเครื่อง
///
/// ฟังก์ชันหลัก:
/// - fetchInstalledApps() - ดึงรายการแอพทั้งหมดในเครื่อง
/// - syncAppsForDevice() - sync รายการแอพไปยัง Firestore
/// - streamApps() - stream แอพจาก Firestore (ตามอุปกรณ์)
/// - streamAllDevicesApps() - รวมแอพจากทุกอุปกรณ์
/// - toggleAppLock() - ล็อก/ปลดล็อกแอพ
///
/// โครงสร้าง Firestore:
/// /users/{parentUid}/children/{childId}/devices/{deviceId}/apps/{appId}
class AppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceService _deviceService = DeviceService();
  static const platform = MethodChannel('com.kidguard/native');

  // ==================== ดึงรายการแอพ ====================
  /// ดึงรายการแอพที่ติดตั้งในเครื่อง
  /// - ใช้ InstalledApps plugin ดึงข้อมูลแอพ
  /// - กรองเฉพาะ launcher apps (แอพที่ผู้ใช้เปิดได้)
  /// - แปลง icon เป็น base64 สำหรับบันทึก
  Future<List<AppInfoModel>> fetchInstalledApps() async {
    try {
      // ดึงแอพทั้งหมดพร้อม icon
      List<AppInfo> allApps = await InstalledApps.getInstalledApps(
        withIcon: true,
      );

      // ดึง launcher apps จาก native (กรองแอพที่ผู้ใช้เปิดได้)
      final List<dynamic> launcherAppsData = await platform.invokeMethod(
        'getLauncherApps',
      );

      // สร้าง map เพื่อตรวจสอบว่าเป็น system app หรือไม่
      final Map<String, bool> systemAppMap = {};
      for (var data in launcherAppsData) {
        if (data is Map) {
          systemAppMap[data['packageName']] = data['isSystem'] ?? false;
        }
      }

      // กรองและแปลงข้อมูล
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

  // ==================== Sync แอพไปยัง Firestore ====================
  /// บันทึกรายการแอพของอุปกรณ์นี้ไปยัง Firestore
  /// - ใช้ batch write เพื่อประสิทธิภาพ
  /// - ไม่ overwrite isLocked เพื่อรักษาการตั้งค่าของผู้ปกครอง
  Future<void> syncAppsForDevice(String parentUid, String childId) async {
    try {
      final deviceId = await _deviceService.getDeviceId();
      final apps = await fetchInstalledApps();
      print(
        'Syncing ${apps.length} apps for child $childId on device $deviceId',
      );

      final collectionRef = _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('devices')
          .doc(deviceId)
          .collection('apps');

      var batch = _firestore.batch();
      int count = 0;

      for (var app in apps) {
        // แปลง package name เป็น document ID (แทน . ด้วย _)
        final docId = app.packageName.replaceAll('.', '_');
        final docRef = collectionRef.doc(docId);

        final data = {
          'packageName': app.packageName,
          'name': app.name,
          'isSystemApp': app.isSystemApp,
          'iconBase64': app.iconBase64,
          // ไม่ overwrite isLocked เพื่อรักษาการตั้งค่าของผู้ปกครอง
        };

        batch.set(docRef, data, SetOptions(merge: true));

        count++;
        // Firestore จำกัด 500 operations ต่อ batch
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

  /// Stream apps for a specific device
  Stream<List<AppInfoModel>> streamAppsForDevice(
    String parentUid,
    String childId,
    String deviceId,
  ) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .collection('apps')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppInfoModel.fromMap(doc.data());
          }).toList();
        });
  }

  /// Stream apps from all devices (combined view)
  Stream<List<AppInfoModel>> streamAllDevicesApps(
    String parentUid,
    String childId,
  ) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .asyncMap((devicesSnapshot) async {
          final Map<String, AppInfoModel> appMap = {};

          for (var deviceDoc in devicesSnapshot.docs) {
            final appsSnapshot = await deviceDoc.reference
                .collection('apps')
                .get();
            for (var appDoc in appsSnapshot.docs) {
              final app = AppInfoModel.fromMap(appDoc.data());
              // Use packageName as key to avoid duplicates, keep the locked state
              if (!appMap.containsKey(app.packageName)) {
                appMap[app.packageName] = app;
              } else if (app.isLocked) {
                // If any device has it locked, keep it locked
                appMap[app.packageName] = app;
              }
            }
          }

          return appMap.values.toList();
        });
  }

  /// Toggle app lock for a specific device
  Future<void> toggleAppLockForDevice(
    String parentUid,
    String childId,
    String deviceId,
    String packageName,
    bool isLocked,
  ) async {
    final docId = packageName.replaceAll('.', '_');

    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .collection('apps')
        .doc(docId)
        .set({'isLocked': isLocked}, SetOptions(merge: true));
  }

  /// Toggle app lock for all devices (global)
  Future<void> toggleAppLockAllDevices(
    String parentUid,
    String childId,
    String packageName,
    bool isLocked,
  ) async {
    final docId = packageName.replaceAll('.', '_');

    final devicesSnapshot = await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .get();

    final batch = _firestore.batch();
    for (var deviceDoc in devicesSnapshot.docs) {
      final appRef = deviceDoc.reference.collection('apps').doc(docId);
      batch.set(appRef, {'isLocked': isLocked}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Stream blocked apps from all devices for this child
  /// Used by child device to get blocklist
  Stream<List<String>> streamBlockedApps(String parentUid, String childId) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .asyncMap((devicesSnapshot) async {
          final Set<String> blockedPackages = {};

          for (var deviceDoc in devicesSnapshot.docs) {
            final appsSnapshot = await deviceDoc.reference
                .collection('apps')
                .where('isLocked', isEqualTo: true)
                .get();

            for (var appDoc in appsSnapshot.docs) {
              final packageName = appDoc.data()['packageName'] as String?;
              if (packageName != null) {
                blockedPackages.add(packageName);
              }
            }
          }

          return blockedPackages.toList();
        });
  }

  // ==================== LEGACY METHODS (for backward compatibility) ====================

  /// Legacy: Sync apps without device ID (deprecated, use syncAppsForDevice)
  @Deprecated('Use syncAppsForDevice instead')
  Future<void> syncApps(String parentUid, String childId) async {
    await syncAppsForDevice(parentUid, childId);
  }

  /// Legacy: Stream apps from old structure (for backward compatibility)
  Stream<List<AppInfoModel>> streamApps(String parentUid, String childId) {
    // First try to get from devices structure, fallback to old structure
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .asyncMap((devicesSnapshot) async {
          if (devicesSnapshot.docs.isEmpty) {
            // Fallback to old structure
            final oldAppsSnapshot = await _firestore
                .collection('users')
                .doc(parentUid)
                .collection('children')
                .doc(childId)
                .collection('apps')
                .get();

            return oldAppsSnapshot.docs.map((doc) {
              return AppInfoModel.fromMap(doc.data());
            }).toList();
          }

          // Use new devices structure
          final Map<String, AppInfoModel> appMap = {};
          for (var deviceDoc in devicesSnapshot.docs) {
            final appsSnapshot = await deviceDoc.reference
                .collection('apps')
                .get();
            for (var appDoc in appsSnapshot.docs) {
              final app = AppInfoModel.fromMap(appDoc.data());
              if (!appMap.containsKey(app.packageName)) {
                appMap[app.packageName] = app;
              } else if (app.isLocked) {
                appMap[app.packageName] = app;
              }
            }
          }

          return appMap.values.toList();
        });
  }

  /// Legacy: Toggle app lock (deprecated)
  @Deprecated('Use toggleAppLockForDevice or toggleAppLockAllDevices instead')
  Future<void> toggleAppLock(
    String parentUid,
    String childId,
    String packageName,
    bool isLocked,
  ) async {
    // Toggle on all devices for backward compatibility
    await toggleAppLockAllDevices(parentUid, childId, packageName, isLocked);
  }

  /// Legacy: Request sync (deprecated, use DeviceService.requestDeviceSync)
  @Deprecated('Use DeviceService.requestDeviceSync instead')
  Future<void> requestSync(String parentUid, String childId) async {
    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .set({'syncRequested': true}, SetOptions(merge: true));

    // Also request sync on all devices
    await _deviceService.requestAllDevicesSync(parentUid, childId);
  }

  /// Legacy: Clear sync request (deprecated, use DeviceService.clearSyncRequest)
  @Deprecated('Use DeviceService.clearSyncRequest instead')
  Future<void> clearSyncRequest(String parentUid, String childId) async {
    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .set({'syncRequested': false}, SetOptions(merge: true));

    await _deviceService.clearSyncRequest(parentUid, childId);
  }

  /// Legacy: Stream sync request (deprecated, use DeviceService.streamSyncRequest)
  @Deprecated('Use DeviceService.streamSyncRequest instead')
  Stream<bool> streamSyncRequest(String parentUid, String childId) {
    return _deviceService.streamSyncRequest(parentUid, childId);
  }
}
