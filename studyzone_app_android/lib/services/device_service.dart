import 'dart:io' show Platform;
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A stable identifier for this device, used to stop the same phone from
/// farming free trials with multiple accounts.
///
/// Prefers the Android ID (`Settings.Secure.ANDROID_ID`) — it survives app
/// reinstalls, which a random per-install id would not. Falls back to a random
/// id persisted in secure storage when the platform id is unavailable.
class DeviceService {
  DeviceService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _uuidKey = 'device_uuid';

  /// Best-available stable device id, or null if nothing could be determined.
  static Future<String?> deviceId() async {
    try {
      if (Platform.isAndroid) {
        final id = await const AndroidId().getId();
        if (id != null && id.trim().isNotEmpty) {
          return id.trim();
        }
      }
    } catch (e) {
      debugPrint('[Device] android id failed: $e');
    }
    return _fallbackUuid();
  }

  static Future<String?> _fallbackUuid() async {
    try {
      var id = await _storage.read(key: _uuidKey);
      if (id == null || id.isEmpty) {
        id = _randomHex();
        await _storage.write(key: _uuidKey, value: id);
      }
      return id;
    } catch (e) {
      debugPrint('[Device] uuid fallback failed: $e');
      return null;
    }
  }

  static String _randomHex() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
