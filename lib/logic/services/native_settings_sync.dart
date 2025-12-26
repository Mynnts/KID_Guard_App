import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to sync settings between Flutter and Native Accessibility Service
/// This allows the Accessibility Service to work independently without Flutter app being open
class NativeSettingsSync {
  static final NativeSettingsSync _instance = NativeSettingsSync._internal();
  factory NativeSettingsSync() => _instance;
  NativeSettingsSync._internal();

  /// Save all settings to JSON file that Accessibility Service can read
  Future<void> syncSettingsToNative({
    required String childId,
    required String parentId,
    required bool isChildModeActive,
    required int screenTime,
    required int limitUsedTime,
    required int dailyTimeLimit,
    DateTime? timeLimitDisabledUntil,
    bool sleepScheduleEnabled = false,
    int bedtimeHour = 20,
    int bedtimeMinute = 0,
    int wakeHour = 7,
    int wakeMinute = 0,
    List<Map<String, dynamic>> quietTimes = const [],
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.parent.path}/files/kid_guard_settings.json',
      );

      final settings = {
        'childId': childId,
        'parentId': parentId,
        'isChildModeActive': isChildModeActive,
        'screenTime': screenTime,
        'limitUsedTime': limitUsedTime,
        'dailyTimeLimit': dailyTimeLimit,
        'timeLimitDisabledUntil':
            timeLimitDisabledUntil?.millisecondsSinceEpoch ?? 0,
        'sleepScheduleEnabled': sleepScheduleEnabled,
        'bedtimeHour': bedtimeHour,
        'bedtimeMinute': bedtimeMinute,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
        'quietTimes': quietTimes,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      };

      await file.writeAsString(jsonEncode(settings));
      print('NativeSettingsSync: Settings synced to native');
    } catch (e) {
      print('NativeSettingsSync: Error syncing settings: $e');
    }
  }

  /// Read screen time data from Accessibility Service
  Future<Map<String, dynamic>?> readScreenTimeFromNative() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.parent.path}/files/screen_time_data.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      print('NativeSettingsSync: Error reading screen time: $e');
    }
    return null;
  }

  /// Sync screen time from native to Firebase
  Future<void> syncScreenTimeToFirebase(String parentId, String childId) async {
    try {
      final data = await readScreenTimeFromNative();
      if (data == null) return;

      final screenTime = data['screenTime'] as int? ?? 0;
      final limitUsedTime = data['limitUsedTime'] as int? ?? 0;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({
            'screenTime': screenTime,
            'limitUsedTime': limitUsedTime,
            'lastActive': FieldValue.serverTimestamp(),
          });

      print('NativeSettingsSync: Screen time synced to Firebase');
    } catch (e) {
      print('NativeSettingsSync: Error syncing to Firebase: $e');
    }
  }

  /// Load settings from Firebase and sync to native
  Future<void> loadFromFirebaseAndSync(String parentId, String childId) async {
    try {
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      if (!childDoc.exists) return;

      final data = childDoc.data()!;

      // Get sleep schedule
      bool sleepEnabled = false;
      int bedtimeHour = 20;
      int bedtimeMinute = 0;
      int wakeHour = 7;
      int wakeMinute = 0;

      if (data['sleepSchedule'] != null) {
        final sleep = data['sleepSchedule'] as Map<String, dynamic>;
        sleepEnabled = sleep['enabled'] ?? false;
        bedtimeHour = sleep['bedtimeHour'] ?? 20;
        bedtimeMinute = sleep['bedtimeMinute'] ?? 0;
        wakeHour = sleep['wakeHour'] ?? 7;
        wakeMinute = sleep['wakeMinute'] ?? 0;
      }

      // Get quiet times
      List<Map<String, dynamic>> quietTimes = [];
      if (data['quietTimes'] != null) {
        quietTimes = List<Map<String, dynamic>>.from(
          (data['quietTimes'] as List).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }

      // Get time limit disabled until
      DateTime? timeLimitDisabledUntil;
      if (data['timeLimitDisabledUntil'] != null) {
        timeLimitDisabledUntil = (data['timeLimitDisabledUntil'] as Timestamp)
            .toDate();
      }

      await syncSettingsToNative(
        childId: childId,
        parentId: parentId,
        isChildModeActive: data['isChildModeActive'] ?? false,
        screenTime: data['screenTime'] ?? 0,
        limitUsedTime: data['limitUsedTime'] ?? data['screenTime'] ?? 0,
        dailyTimeLimit: data['dailyTimeLimit'] ?? 0,
        timeLimitDisabledUntil: timeLimitDisabledUntil,
        sleepScheduleEnabled: sleepEnabled,
        bedtimeHour: bedtimeHour,
        bedtimeMinute: bedtimeMinute,
        wakeHour: wakeHour,
        wakeMinute: wakeMinute,
        quietTimes: quietTimes,
      );
    } catch (e) {
      print('NativeSettingsSync: Error loading from Firebase: $e');
    }
  }

  /// Enable child mode and sync to native
  Future<void> enableChildMode(String parentId, String childId) async {
    await loadFromFirebaseAndSync(parentId, childId);

    // Update just the child mode flag
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.parent.path}/files/kid_guard_settings.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final settings = jsonDecode(content) as Map<String, dynamic>;
      settings['isChildModeActive'] = true;
      await file.writeAsString(jsonEncode(settings));
    }
  }

  /// Disable child mode
  Future<void> disableChildMode() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.parent.path}/files/kid_guard_settings.json',
      );

      if (await file.exists()) {
        final content = await file.readAsString();
        final settings = jsonDecode(content) as Map<String, dynamic>;
        settings['isChildModeActive'] = false;
        await file.writeAsString(jsonEncode(settings));
      }
    } catch (e) {
      print('NativeSettingsSync: Error disabling child mode: $e');
    }
  }
}
