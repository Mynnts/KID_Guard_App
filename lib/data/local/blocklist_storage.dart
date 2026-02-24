import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BlocklistStorage {
  static const String _fileName = 'blocked_apps.json';
  static const platform = MethodChannel('com.kidguard/native');

  /// Get the files directory path that matches Kotlin's applicationContext.filesDir
  Future<String> get _localPath async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        // First try native method if available via channel
        final String? path = await platform.invokeMethod('getFilesDir');
        if (path != null) return path;

        // Fallback to standard path_provider supported directory
        directory = await getApplicationSupportDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } catch (e) {
      // Final fallback if everything fails
      return '/data/data/com.seniorproject.kid_guard/files';
    }
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
    // Blocklist saved
  }

  Future<List<String>> readBlocklist() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      String contents = await file.readAsString();
      List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.cast<String>();
    } catch (e) {
      // Error reading blocklist
      return [];
    }
  }
}
