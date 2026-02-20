import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String deviceId;
  final String deviceName;
  final DateTime? lastActive;
  final bool isOnline;
  final bool syncRequested;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    this.lastActive,
    this.isOnline = false,
    this.syncRequested = false,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map, String id) {
    return DeviceModel(
      deviceId: id,
      deviceName: map['deviceName'] ?? 'Unknown Device',
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : null,
      isOnline: map['isOnline'] ?? false,
      syncRequested: map['syncRequested'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isOnline': isOnline,
      'syncRequested': syncRequested,
    };
  }
}
