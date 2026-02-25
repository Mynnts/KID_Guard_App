import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/device_model.dart';

void main() {
  group('DeviceModel', () {
    group('fromMap', () {
      test('creates DeviceModel with full data', () {
        final now = DateTime(2026, 2, 25, 10, 0, 0);
        final map = {
          'deviceName': 'Samsung Galaxy A54',
          'lastActive': Timestamp.fromDate(now),
          'isOnline': true,
          'syncRequested': true,
        };

        final device = DeviceModel.fromMap(map, 'device-001');

        expect(device.deviceId, 'device-001');
        expect(device.deviceName, 'Samsung Galaxy A54');
        expect(device.lastActive, now);
        expect(device.isOnline, isTrue);
        expect(device.syncRequested, isTrue);
      });

      test('handles missing fields with defaults', () {
        final device = DeviceModel.fromMap({}, 'device-002');

        expect(device.deviceId, 'device-002');
        expect(device.deviceName, 'Unknown Device');
        expect(device.lastActive, isNull);
        expect(device.isOnline, isFalse);
        expect(device.syncRequested, isFalse);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2026, 1, 15, 14, 30, 0);
        final device = DeviceModel(
          deviceId: 'd1',
          deviceName: 'Pixel 8',
          lastActive: now,
          isOnline: true,
          syncRequested: true,
        );

        final map = device.toMap();

        expect(map['deviceName'], 'Pixel 8');
        expect(map['lastActive'], isA<Timestamp>());
        expect((map['lastActive'] as Timestamp).toDate(), now);
        expect(map['isOnline'], isTrue);
        expect(map['syncRequested'], isTrue);
      });

      test('handles null lastActive in toMap', () {
        final device = DeviceModel(deviceId: 'd2', deviceName: 'Test');

        final map = device.toMap();

        expect(map['lastActive'], isNull);
      });
    });
  });
}
