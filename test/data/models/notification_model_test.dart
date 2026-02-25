import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    group('fromMap', () {
      test('creates NotificationModel with full data', () {
        final timestamp = DateTime(2026, 2, 25, 12, 0, 0);
        final map = {
          'title': 'App Blocked',
          'message': 'YouTube was blocked',
          'timestamp': Timestamp.fromDate(timestamp),
          'type': 'alert',
          'category': 'app_blocked',
          'isRead': true,
          'iconName': 'block_rounded',
          'colorValue': 0xFFFF0000,
        };

        final notif = NotificationModel.fromMap(map, 'notif-001');

        expect(notif.id, 'notif-001');
        expect(notif.title, 'App Blocked');
        expect(notif.message, 'YouTube was blocked');
        expect(notif.timestamp, timestamp);
        expect(notif.type, 'alert');
        expect(notif.category, 'app_blocked');
        expect(notif.isRead, isTrue);
        expect(notif.iconName, 'block_rounded');
        expect(notif.colorValue, 0xFFFF0000);
      });

      test('handles missing fields with defaults', () {
        final notif = NotificationModel.fromMap({}, 'notif-002');

        expect(notif.id, 'notif-002');
        expect(notif.title, '');
        expect(notif.message, '');
        expect(notif.type, 'system');
        expect(notif.category, 'system');
        expect(notif.isRead, isFalse);
        expect(notif.iconName, isNull);
        expect(notif.colorValue, isNull);
      });
    });

    group('toMap', () {
      test('serializes correctly with Timestamp', () {
        final timestamp = DateTime(2026, 3, 1, 9, 30, 0);
        final notif = NotificationModel(
          id: 'n1',
          title: 'Test',
          message: 'Msg',
          timestamp: timestamp,
          type: 'system',
          category: 'system',
          iconName: 'settings_rounded',
          colorValue: 0xFF00FF00,
        );

        final map = notif.toMap();

        expect(map['title'], 'Test');
        expect(map['message'], 'Msg');
        expect(map['timestamp'], isA<Timestamp>());
        expect((map['timestamp'] as Timestamp).toDate(), timestamp);
        expect(map['type'], 'system');
        expect(map['category'], 'system');
        expect(map['isRead'], isFalse);
        expect(map['iconName'], 'settings_rounded');
        expect(map['colorValue'], 0xFF00FF00);
      });
    });

    group('icon getter', () {
      NotificationModel _makeNotif({String? iconName}) {
        return NotificationModel(
          id: 'n',
          title: '',
          message: '',
          timestamp: DateTime.now(),
          type: 'system',
          iconName: iconName,
        );
      }

      test('returns correct icons for known names', () {
        expect(
          _makeNotif(iconName: 'person_add_rounded').icon,
          Icons.person_add_rounded,
        );
        expect(
          _makeNotif(iconName: 'settings_rounded').icon,
          Icons.settings_rounded,
        );
        expect(
          _makeNotif(iconName: 'warning_rounded').icon,
          Icons.warning_rounded,
        );
        expect(
          _makeNotif(iconName: 'check_circle_rounded').icon,
          Icons.check_circle_rounded,
        );
        expect(_makeNotif(iconName: 'edit_rounded').icon, Icons.edit_rounded);
        expect(
          _makeNotif(iconName: 'vpn_key_rounded').icon,
          Icons.vpn_key_rounded,
        );
        expect(
          _makeNotif(iconName: 'schedule_rounded').icon,
          Icons.schedule_rounded,
        );
        expect(
          _makeNotif(iconName: 'location_on_rounded').icon,
          Icons.location_on_rounded,
        );
        expect(_makeNotif(iconName: 'block_rounded').icon, Icons.block_rounded);
        expect(
          _makeNotif(iconName: 'shield_rounded').icon,
          Icons.shield_rounded,
        );
      });

      test('returns default icon for unknown name', () {
        expect(
          _makeNotif(iconName: 'unknown_icon').icon,
          Icons.notifications_rounded,
        );
      });

      test('returns default icon when iconName is null', () {
        expect(_makeNotif(iconName: null).icon, Icons.notifications_rounded);
      });
    });

    group('color getter', () {
      NotificationModel _makeNotif({required String type, int? colorValue}) {
        return NotificationModel(
          id: 'n',
          title: '',
          message: '',
          timestamp: DateTime.now(),
          type: type,
          colorValue: colorValue,
        );
      }

      test('uses colorValue when provided', () {
        final notif = _makeNotif(type: 'system', colorValue: 0xFFABCDEF);
        expect(notif.color, const Color(0xFFABCDEF));
      });

      test('returns red for alert type', () {
        expect(_makeNotif(type: 'alert').color, Colors.red);
      });

      test('returns orange for warning type', () {
        expect(_makeNotif(type: 'warning').color, Colors.orange);
      });

      test('returns green for success type', () {
        expect(_makeNotif(type: 'success').color, Colors.green);
      });

      test('returns blue for unknown/default type', () {
        expect(_makeNotif(type: 'system').color, Colors.blue);
        expect(_makeNotif(type: 'anything').color, Colors.blue);
      });
    });
  });
}
