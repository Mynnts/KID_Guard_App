import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/app_info_model.dart';

void main() {
  group('AppInfoModel', () {
    group('fromMap', () {
      test('creates AppInfoModel with full data', () {
        final map = {
          'packageName': 'com.google.youtube',
          'name': 'YouTube',
          'isSystemApp': false,
          'isLocked': true,
          'iconBase64': 'base64data',
        };

        final app = AppInfoModel.fromMap(map);

        expect(app.packageName, 'com.google.youtube');
        expect(app.name, 'YouTube');
        expect(app.isSystemApp, isFalse);
        expect(app.isLocked, isTrue);
        expect(app.iconBase64, 'base64data');
      });

      test('handles missing fields with defaults', () {
        final app = AppInfoModel.fromMap({});

        expect(app.packageName, '');
        expect(app.name, '');
        expect(app.isSystemApp, isFalse);
        expect(app.isLocked, isFalse);
        expect(app.iconBase64, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final app = AppInfoModel(
          packageName: 'com.example.app',
          name: 'Example',
          isSystemApp: true,
          isLocked: true,
          iconBase64: 'icon',
        );

        final map = app.toMap();

        expect(map['packageName'], 'com.example.app');
        expect(map['name'], 'Example');
        expect(map['isSystemApp'], isTrue);
        expect(map['isLocked'], isTrue);
        expect(map['iconBase64'], 'icon');
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final app = AppInfoModel(
          packageName: 'com.app',
          name: 'App',
          isSystemApp: false,
          isLocked: false,
        );

        final copy = app.copyWith();

        expect(copy.packageName, app.packageName);
        expect(copy.name, app.name);
        expect(copy.isSystemApp, app.isSystemApp);
        expect(copy.isLocked, app.isLocked);
        expect(copy.iconBase64, app.iconBase64);
      });

      test('overrides isLocked only', () {
        final app = AppInfoModel(
          packageName: 'com.app',
          name: 'App',
          isSystemApp: false,
          isLocked: false,
        );

        final locked = app.copyWith(isLocked: true);

        expect(locked.isLocked, isTrue);
        expect(locked.packageName, 'com.app'); // unchanged
        expect(locked.name, 'App'); // unchanged
      });

      test('overrides all fields', () {
        final app = AppInfoModel(
          packageName: 'old',
          name: 'Old',
          isSystemApp: false,
        );

        final copy = app.copyWith(
          packageName: 'new.pkg',
          name: 'New',
          isSystemApp: true,
          isLocked: true,
          iconBase64: 'newIcon',
        );

        expect(copy.packageName, 'new.pkg');
        expect(copy.name, 'New');
        expect(copy.isSystemApp, isTrue);
        expect(copy.isLocked, isTrue);
        expect(copy.iconBase64, 'newIcon');
      });
    });

    group('constructor defaults', () {
      test('isLocked defaults to false', () {
        final app = AppInfoModel(
          packageName: 'a',
          name: 'b',
          isSystemApp: false,
        );
        expect(app.isLocked, isFalse);
      });

      test('iconBase64 defaults to null', () {
        final app = AppInfoModel(
          packageName: 'a',
          name: 'b',
          isSystemApp: false,
        );
        expect(app.iconBase64, isNull);
      });
    });
  });
}
