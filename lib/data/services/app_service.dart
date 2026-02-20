// ==================== นำเข้า Packages ====================
import 'dart:convert';
import 'dart:async';
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

    final batch = _firestore.batch();

    // 1. Update on specific device
    final deviceAppRef = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .collection('apps')
        .doc(docId);
    batch.set(deviceAppRef, {
      'isLocked': isLocked,
      'packageName': packageName,
    }, SetOptions(merge: true));

    // 2. Also update legacy for consistency
    final legacyAppRef = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('apps')
        .doc(docId);
    batch.set(legacyAppRef, {
      'isLocked': isLocked,
      'packageName': packageName,
    }, SetOptions(merge: true));

    await batch.commit();
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

    // 1. Update on all registered devices
    for (var deviceDoc in devicesSnapshot.docs) {
      final appRef = deviceDoc.reference.collection('apps').doc(docId);
      batch.set(appRef, {
        'isLocked': isLocked,
        'packageName': packageName,
      }, SetOptions(merge: true));
    }

    // 2. Update legacy structure (fallback)
    // This ensures that if the UI is reading from the legacy collection (because no devices are found),
    // the lock status is still updated and reflected in the UI.
    final legacyAppRef = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('apps')
        .doc(docId);
    batch.set(legacyAppRef, {
      'isLocked': isLocked,
      'packageName': packageName,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Stream blocked apps from all devices for this child
  /// Used by child device to get blocklist
  Stream<List<String>> streamBlockedApps(String parentUid, String childId) {
    final controller = StreamController<List<String>>();
    StreamSubscription? legacySub;
    StreamSubscription? devicesListSub;
    final Map<String, StreamSubscription> deviceAppSubs = {};

    final Set<String> legacyBlocked = {};
    final Map<String, Set<String>> deviceBlocked = {};

    void emitMerged() {
      if (controller.isClosed) return;
      final Set<String> merged = {...legacyBlocked};
      for (final blocked in deviceBlocked.values) {
        merged.addAll(blocked);
      }
      controller.add(merged.toList());
    }

    // 1. Listen to legacy structure (Real-time)
    legacySub = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('apps')
        .where('isLocked', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          legacyBlocked.clear();
          for (var doc in snapshot.docs) {
            final pkg = doc.data()['packageName'] as String?;
            if (pkg != null) legacyBlocked.add(pkg);
          }
          emitMerged();
        });

    // 2. Listen to devices and their apps (Real-time)
    devicesListSub = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .listen((devicesSnapshot) {
          // Clean up subs for removed devices
          final currentDeviceIds = devicesSnapshot.docs
              .map((d) => d.id)
              .toSet();
          deviceAppSubs.keys.toList().forEach((id) {
            if (!currentDeviceIds.contains(id)) {
              deviceAppSubs[id]?.cancel();
              deviceAppSubs.remove(id);
              deviceBlocked.remove(id);
            }
          });

          // Add subs for new devices
          for (var deviceDoc in devicesSnapshot.docs) {
            if (!deviceAppSubs.containsKey(deviceDoc.id)) {
              deviceAppSubs[deviceDoc.id] = deviceDoc.reference
                  .collection('apps')
                  .where('isLocked', isEqualTo: true)
                  .snapshots()
                  .listen((appsSnapshot) {
                    final blocked = appsSnapshot.docs
                        .map((doc) => doc.data()['packageName'] as String?)
                        .whereType<String>()
                        .toSet();
                    deviceBlocked[deviceDoc.id] = blocked;
                    emitMerged();
                  });
            }
          }
          emitMerged();
        });

    controller.onCancel = () {
      legacySub?.cancel();
      devicesListSub?.cancel();
      for (var sub in deviceAppSubs.values) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  // ==================== LEGACY METHODS (for backward compatibility) ====================

  /// Legacy: Sync apps without device ID (deprecated, use syncAppsForDevice)
  @Deprecated('Use syncAppsForDevice instead')
  Future<void> syncApps(String parentUid, String childId) async {
    await syncAppsForDevice(parentUid, childId);
  }

  /// Legacy: Stream apps from old structure (for backward compatibility)
  Stream<List<AppInfoModel>> streamApps(String parentUid, String childId) {
    final controller = StreamController<List<AppInfoModel>>();
    StreamSubscription? devicesListSub;
    StreamSubscription? legacySub;
    final Map<String, StreamSubscription> deviceAppSubs = {};
    final Map<String, List<AppInfoModel>> deviceAppsMap = {};
    List<AppInfoModel> legacyApps = [];

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, AppInfoModel> mergedMap = {};

      // 1. Process legacy apps
      for (var app in legacyApps) {
        mergedMap[app.packageName] = app;
      }

      // 2. Process all device apps
      // If a package exists in multiple devices, we merge status (if any is locked, it's locked)
      for (var apps in deviceAppsMap.values) {
        for (var app in apps) {
          if (!mergedMap.containsKey(app.packageName) || app.isLocked) {
            mergedMap[app.packageName] = app;
          }
        }
      }
      controller.add(mergedMap.values.toList());
    }

    devicesListSub = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .listen((devicesSnapshot) {
          // Clean up subs for removed devices
          final currentDeviceIds = devicesSnapshot.docs
              .map((d) => d.id)
              .toSet();
          deviceAppSubs.keys.toList().forEach((id) {
            if (!currentDeviceIds.contains(id)) {
              deviceAppSubs[id]?.cancel();
              deviceAppSubs.remove(id);
              deviceAppsMap.remove(id);
            }
          });

          if (devicesSnapshot.docs.isEmpty) {
            // Fallback to legacy structure
            legacySub ??= _firestore
                .collection('users')
                .doc(parentUid)
                .collection('children')
                .doc(childId)
                .collection('apps')
                .snapshots()
                .listen((snap) {
                  legacyApps = snap.docs
                      .map((d) => AppInfoModel.fromMap(d.data()))
                      .toList();
                  emitMerged();
                });
          } else {
            // We have devices, stop legacy if it was running
            legacySub?.cancel();
            legacySub = null;
            legacyApps = [];

            for (var deviceDoc in devicesSnapshot.docs) {
              if (!deviceAppSubs.containsKey(deviceDoc.id)) {
                deviceAppSubs[deviceDoc.id] = deviceDoc.reference
                    .collection('apps')
                    .snapshots()
                    .listen((appsSnapshot) {
                      deviceAppsMap[deviceDoc.id] = appsSnapshot.docs
                          .map((doc) => AppInfoModel.fromMap(doc.data()))
                          .toList();
                      emitMerged();
                    });
              }
            }
          }
          emitMerged();
        });

    controller.onCancel = () {
      devicesListSub?.cancel();
      legacySub?.cancel();
      for (var sub in deviceAppSubs.values) {
        sub.cancel();
      }
    };

    return controller.stream;
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
