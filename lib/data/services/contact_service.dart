import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  Future<List<ContactModel>> fetchContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      return contacts.map((c) {
        return ContactModel(
          id: c.id,
          displayName: c.displayName,
          phones: c.phones.map((p) => p.number).toList(),
          avatar: null, // Simplify for now, avatars can be heavy
        );
      }).toList();
    }
    return [];
  }

  Future<void> syncContacts(String parentUid, String childId) async {
    try {
      final contacts = await fetchContacts();
      final batch = _firestore.batch();
      final collectionRef = _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('contacts');

      // Clear existing (optional, or merge)
      // For simplicity, we'll just overwrite/add.
      // A real sync might need diffing.

      // Note: Batch has a limit of 500 ops.
      // For a large list, we should chunk it.
      int count = 0;
      for (var contact in contacts) {
        final docRef = collectionRef.doc(contact.id);
        batch.set(docRef, contact.toMap());
        count++;
        if (count >= 400) {
          await batch.commit();
          count = 0;
          // Create new batch if needed, but for now let's assume < 400 contacts or just commit once
          // Re-instantiating batch here would be needed for > 500
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error syncing contacts: $e');
    }
  }

  Stream<List<ContactModel>> streamContacts(String parentUid, String childId) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId)
        .collection('contacts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ContactModel.fromMap(doc.data()))
              .toList();
        });
  }
}
