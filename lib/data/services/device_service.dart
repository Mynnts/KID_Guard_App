import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _cachedDeviceId;
  String? _cachedDeviceName;

  /// Get unique device ID
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Use Android ID which is unique per device per app signing key
      _cachedDeviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _cachedDeviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
    } else {
      _cachedDeviceId = 'unknown_platform';
    }

    return _cachedDeviceId!;
  }

  /// Get device name (model)
  Future<String> getDeviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      _cachedDeviceName = '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _cachedDeviceName = iosInfo.utsname.machine;
    } else {
      _cachedDeviceName = 'Unknown Device';
    }

    return _cachedDeviceName!;
  }

  /// Register this device for a child profile
  Future<void> registerDevice(String parentUid, String childId) async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();

    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .set({
          'deviceName': deviceName,
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
          'syncRequested': false,
        }, SetOptions(merge: true));
  }

  /// Update device online status
  Future<void> updateDeviceStatus(
    String parentUid,
    String childId,
    bool isOnline,
  ) async {
    final deviceId = await getDeviceId();

    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .set({
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': isOnline,
        }, SetOptions(merge: true));
  }

  /// Stream all devices for a child
  Stream<List<DeviceModel>> streamDevices(String parentUid, String childId) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DeviceModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Request sync for a specific device
  Future<void> requestDeviceSync(
    String parentUid,
    String childId,
    String deviceId,
  ) async {
    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .set({'syncRequested': true}, SetOptions(merge: true));
  }

  /// Request sync for all devices of a child
  Future<void> requestAllDevicesSync(String parentUid, String childId) async {
    final devicesSnapshot = await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .get();

    final batch = _firestore.batch();
    for (var doc in devicesSnapshot.docs) {
      batch.update(doc.reference, {'syncRequested': true});
    }
    await batch.commit();
  }

  /// Clear sync request for this device
  Future<void> clearSyncRequest(String parentUid, String childId) async {
    final deviceId = await getDeviceId();

    await _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .set({'syncRequested': false}, SetOptions(merge: true));
  }

  /// Stream sync request for this device
  Stream<bool> streamSyncRequest(String parentUid, String childId) async* {
    final deviceId = await getDeviceId();

    yield* _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data()?['syncRequested'] ?? false;
          }
          return false;
        });
  }
}
