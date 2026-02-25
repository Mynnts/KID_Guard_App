import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('fromMap', () {
      test('creates UserModel with full data', () {
        final map = {
          'email': 'parent@test.com',
          'displayName': 'Test Parent',
          'role': 'parent',
          'childIds': ['child1', 'child2'],
          'pin': '123456',
        };

        final user = UserModel.fromMap(map, 'uid-001');

        expect(user.uid, 'uid-001');
        expect(user.email, 'parent@test.com');
        expect(user.displayName, 'Test Parent');
        expect(user.role, 'parent');
        expect(user.childIds, ['child1', 'child2']);
        expect(user.pin, '123456');
      });

      test('handles missing fields with defaults', () {
        final user = UserModel.fromMap({}, 'uid-002');

        expect(user.uid, 'uid-002');
        expect(user.email, '');
        expect(user.displayName, isNull);
        expect(user.role, 'parent');
        expect(user.childIds, isEmpty);
        expect(user.pin, isNull);
      });

      test('handles null displayName and pin', () {
        final map = {
          'email': 'test@test.com',
          'displayName': null,
          'pin': null,
        };

        final user = UserModel.fromMap(map, 'uid-003');

        expect(user.displayName, isNull);
        expect(user.pin, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final user = UserModel(
          uid: 'uid-001',
          email: 'parent@test.com',
          displayName: 'Test Parent',
          role: 'parent',
          childIds: ['c1', 'c2'],
          pin: '1234',
        );

        final map = user.toMap();

        expect(map['email'], 'parent@test.com');
        expect(map['displayName'], 'Test Parent');
        expect(map['role'], 'parent');
        expect(map['childIds'], ['c1', 'c2']);
        expect(map['pin'], '1234');
        expect(map.containsKey('uid'), isFalse); // uid is NOT in toMap
      });

      test('serializes with default values', () {
        final user = UserModel(uid: 'uid-001', email: 'a@b.com');

        final map = user.toMap();

        expect(map['role'], 'parent');
        expect(map['childIds'], isEmpty);
        expect(map['displayName'], isNull);
        expect(map['pin'], isNull);
      });
    });

    group('constructor defaults', () {
      test('role defaults to parent', () {
        final user = UserModel(uid: 'u1', email: 'a@b.com');
        expect(user.role, 'parent');
      });

      test('childIds defaults to empty list', () {
        final user = UserModel(uid: 'u1', email: 'a@b.com');
        expect(user.childIds, isEmpty);
      });
    });
  });
}
