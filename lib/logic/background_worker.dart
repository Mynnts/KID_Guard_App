import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/blocklist_storage.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();

      // We need childId and parentUid.
      // Since WorkManager spawns a new isolate, we can't access Provider.
      // We must read from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('current_child_id');
      final parentUid = prefs.getString('current_parent_uid');

      if (childId != null && parentUid != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentUid)
            .collection('children')
            .doc(childId)
            .collection('apps')
            .where('isLocked', isEqualTo: true)
            .get();

        final blockedApps = snapshot.docs
            .map((doc) => doc['packageName'] as String)
            .toList();

        await BlocklistStorage().saveBlocklist(blockedApps);
      } else {}

      return Future.value(true);
    } catch (e) {
      // Background sync failed
      return Future.value(false);
    }
  });
}
