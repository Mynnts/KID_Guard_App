import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class BlocklistStorage {
  static const String _fileName = 'blocked_apps.json';
  static const platform = MethodChannel('com.kidguard/native');

  /// Get the files directory path that matches Kotlin's applicationContext.filesDir
  Future<String> get _localPath async {
    try {
      // Try to get the native files directory path
      final String? path = await platform.invokeMethod('getFilesDir');
      if (path != null) {
        return path;
      }
    } catch (e) {
      print("Error getting native files dir: $e");
    }
    // Fallback: construct the path manually (this is the standard Android files dir)
    // On Android, filesDir is typically /data/data/<package>/files
    return '/data/data/com.seniorproject.kid_guard/files';
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> saveBlocklist(List<String> blockedApps) async {
    final file = await _localFile;
    // Ensure directory exists
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // Native expects a JSON array of strings
    String jsonString = jsonEncode(blockedApps);
    await file.writeAsString(jsonString, flush: true);
    print("Blocklist saved to ${file.path} with ${blockedApps.length} apps");
  }

  Future<List<String>> readBlocklist() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      String contents = await file.readAsString();
      List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.cast<String>();
    } catch (e) {
      print("Error reading blocklist: $e");
      return [];
    }
  }
}
