import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/contact_model.dart';

void main() {
  group('ContactModel', () {
    group('fromMap', () {
      test('creates ContactModel with full data', () {
        final map = {
          'id': 'contact-001',
          'displayName': 'Mom',
          'phones': ['0812345678', '0898765432'],
          'avatar': 'base64EncodedAvatar',
        };

        final contact = ContactModel.fromMap(map);

        expect(contact.id, 'contact-001');
        expect(contact.displayName, 'Mom');
        expect(contact.phones, hasLength(2));
        expect(contact.phones[0], '0812345678');
        expect(contact.avatar, 'base64EncodedAvatar');
      });

      test('handles missing fields with defaults', () {
        final contact = ContactModel.fromMap({});

        expect(contact.id, '');
        expect(contact.displayName, '');
        expect(contact.phones, isEmpty);
        expect(contact.avatar, isNull);
      });

      test('handles empty phones list', () {
        final map = {'id': 'c1', 'displayName': 'Test', 'phones': <String>[]};

        final contact = ContactModel.fromMap(map);
        expect(contact.phones, isEmpty);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final contact = ContactModel(
          id: 'c1',
          displayName: 'Dad',
          phones: ['0811111111'],
          avatar: 'avatarData',
        );

        final map = contact.toMap();

        expect(map['id'], 'c1');
        expect(map['displayName'], 'Dad');
        expect(map['phones'], ['0811111111']);
        expect(map['avatar'], 'avatarData');
      });

      test('serializes without avatar', () {
        final contact = ContactModel(id: 'c2', displayName: 'Test', phones: []);

        final map = contact.toMap();
        expect(map['avatar'], isNull);
        expect(map['phones'], isEmpty);
      });
    });
  });
}
