import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.kid_guard/overlay',
  );

  Future<void> showBlockOverlay(String packageName) async {
    try {
      await _channel.invokeMethod('showOverlay', {'packageName': packageName});
    } catch (e) {
      print('Error showing overlay: $e');
    }
  }

  Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } catch (e) {
      print('Error hiding overlay: $e');
    }
  }

  Future<bool> checkPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkPermission');
      return result;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }
}
