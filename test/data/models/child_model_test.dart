import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/child_model.dart';

void main() {
  group('ChildModel', () {
    group('fromMap', () {
      test('creates ChildModel with full data', () {
        final now = DateTime(2026, 2, 25, 12, 0, 0);
        final sessionStart = DateTime(2026, 2, 25, 8, 0, 0);
        final disabledUntil = DateTime(2026, 2, 25, 18, 0, 0);

        final map = {
          'parentId': 'parent-001',
          'name': 'Som',
          'age': 8,
          'avatar': 'boy_1',
          'screenTime': 3600,
          'limitUsedTime': 1800,
          'isLocked': true,
          'isOnline': true,
          'lastActive': Timestamp.fromDate(now),
          'sessionStartTime': Timestamp.fromDate(sessionStart),
          'dailyTimeLimit': 7200,
          'isChildModeActive': true,
          'unlockRequested': true,
          'timeLimitDisabledUntil': Timestamp.fromDate(disabledUntil),
          'lockReason': 'time_limit',
          'points': 50,
        };

        final child = ChildModel.fromMap(map, 'child-001');

        expect(child.id, 'child-001');
        expect(child.parentId, 'parent-001');
        expect(child.name, 'Som');
        expect(child.age, 8);
        expect(child.avatar, 'boy_1');
        expect(child.screenTime, 3600);
        expect(child.limitUsedTime, 1800);
        expect(child.isLocked, isTrue);
        expect(child.isOnline, isTrue);
        expect(child.lastActive, now);
        expect(child.sessionStartTime, sessionStart);
        expect(child.dailyTimeLimit, 7200);
        expect(child.isChildModeActive, isTrue);
        expect(child.unlockRequested, isTrue);
        expect(child.timeLimitDisabledUntil, disabledUntil);
        expect(child.lockReason, 'time_limit');
        expect(child.points, 50);
      });

      test('handles missing fields with defaults', () {
        final child = ChildModel.fromMap({}, 'child-002');

        expect(child.id, 'child-002');
        expect(child.parentId, '');
        expect(child.name, '');
        expect(child.age, 0);
        expect(child.avatar, isNull);
        expect(child.screenTime, 0);
        expect(child.limitUsedTime, 0);
        expect(child.isLocked, isFalse);
        expect(child.isOnline, isFalse);
        expect(child.lastActive, isNull);
        expect(child.sessionStartTime, isNull);
        expect(child.dailyTimeLimit, 0);
        expect(child.isChildModeActive, isFalse);
        expect(child.unlockRequested, isFalse);
        expect(child.timeLimitDisabledUntil, isNull);
        expect(child.lockReason, '');
        expect(child.points, 0);
      });

      test('limitUsedTime falls back to screenTime when missing', () {
        final map = {
          'screenTime': 5000,
          // limitUsedTime intentionally missing
        };

        final child = ChildModel.fromMap(map, 'child-003');

        expect(child.limitUsedTime, 5000);
        expect(child.screenTime, 5000);
      });

      test('limitUsedTime uses own value when present', () {
        final map = {'screenTime': 5000, 'limitUsedTime': 2000};

        final child = ChildModel.fromMap(map, 'child-004');

        expect(child.limitUsedTime, 2000);
        expect(child.screenTime, 5000);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2026, 1, 1);
        final child = ChildModel(
          id: 'c1',
          parentId: 'p1',
          name: 'Nut',
          age: 5,
          avatar: 'girl_2',
          screenTime: 100,
          limitUsedTime: 50,
          isLocked: true,
          isOnline: true,
          lastActive: now,
          sessionStartTime: now,
          dailyTimeLimit: 3600,
          isChildModeActive: true,
          unlockRequested: false,
          timeLimitDisabledUntil: now,
          lockReason: 'blocked_app',
          points: 10,
        );

        final map = child.toMap();

        expect(map['parentId'], 'p1');
        expect(map['name'], 'Nut');
        expect(map['age'], 5);
        expect(map['avatar'], 'girl_2');
        expect(map['screenTime'], 100);
        expect(map['limitUsedTime'], 50);
        expect(map['isLocked'], isTrue);
        expect(map['isOnline'], isTrue);
        expect(map['lastActive'], now);
        expect(map['dailyTimeLimit'], 3600);
        expect(map['isChildModeActive'], isTrue);
        expect(map['unlockRequested'], isFalse);
        expect(map['lockReason'], 'blocked_app');
        expect(map['points'], 10);
        expect(map.containsKey('id'), isFalse); // id is NOT in toMap
      });
    });

    group('constructor defaults', () {
      test('has correct default values', () {
        final child = ChildModel(id: 'c1', parentId: 'p1', name: 'A', age: 3);

        expect(child.screenTime, 0);
        expect(child.limitUsedTime, 0);
        expect(child.isLocked, isFalse);
        expect(child.isOnline, isFalse);
        expect(child.dailyTimeLimit, 0);
        expect(child.isChildModeActive, isFalse);
        expect(child.unlockRequested, isFalse);
        expect(child.lockReason, '');
        expect(child.points, 0);
      });
    });
  });
}
