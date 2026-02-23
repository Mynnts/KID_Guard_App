import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.kid_guard/overlay',
  );

  Future<void> showBlockOverlay(String packageName) async {
    try {
      await _channel.invokeMethod('showOverlay', {'packageName': packageName});
    } catch (e) {
      // Error showing overlay
    }
  }

  Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } catch (e) {
      // Error hiding overlay
    }
  }

  Future<bool> checkPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkPermission');
      return result;
    } catch (e) {
      // Error checking overlay permission
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      // Error requesting overlay permission
    }
  }
}
