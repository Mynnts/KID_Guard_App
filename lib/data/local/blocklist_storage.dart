import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BlocklistStorage {
  static const String _fileName = 'blocked_apps.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> saveBlocklist(List<String> blockedApps) async {
    final file = await _localFile;
    // Native expects a JSON array of strings
    String jsonString = jsonEncode(blockedApps);
    await file.writeAsString(jsonString, flush: true);
    print("Blocklist saved to ${file.path}");
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
