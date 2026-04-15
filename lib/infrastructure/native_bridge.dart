import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.face_imv/native');

  static Future<String?> getPlatformVersion() async {
    try {
      final String? version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      return "Failed to get platform version: '${e.message}'.";
    }
  }

  static Future<void> triggerHaptic() async {
    try {
      await _channel.invokeMethod('triggerHaptic');
    } catch (e) {
      // Silently fail if not implemented
    }
  }
}
