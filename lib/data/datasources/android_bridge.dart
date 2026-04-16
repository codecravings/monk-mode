import 'package:flutter/services.dart';
import '../models/app_info.dart';

class AndroidBridge {
  static const _channel = MethodChannel('com.monkmode.app/bridge');

  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return _mockApps();
      return result.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return AppInfo(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          isSystemApp: map['isSystemApp'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return _mockApps();
    }
  }

  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<bool> isUsageStatsPermissionGranted() async {
    try {
      return await _channel
              .invokeMethod<bool>('isUsageStatsPermissionGranted') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } catch (_) {}
  }

  static Future<Map<String, int>> getUsageStats(
      int startTimestamp, int endTimestamp) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getUsageStats',
        {'start': startTimestamp, 'end': endTimestamp},
      );
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k as String, v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (_) {}
  }

  static Future<void> updateLockedPackages(List<String> packages) async {
    try {
      await _channel
          .invokeMethod('updateLockedPackages', {'packages': packages});
    } catch (_) {}
  }

  static List<AppInfo> _mockApps() => [
        AppInfo(packageName: 'com.instagram.android', appName: 'Instagram'),
        AppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp'),
        AppInfo(packageName: 'com.google.android.youtube', appName: 'YouTube'),
        AppInfo(packageName: 'com.twitter.android', appName: 'X (Twitter)'),
        AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook'),
        AppInfo(packageName: 'com.snapchat.android', appName: 'Snapchat'),
        AppInfo(packageName: 'com.reddit.frontpage', appName: 'Reddit'),
        AppInfo(packageName: 'com.netflix.mediaclient', appName: 'Netflix'),
        AppInfo(
            packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
        AppInfo(packageName: 'com.spotify.music', appName: 'Spotify'),
        AppInfo(packageName: 'com.discord', appName: 'Discord'),
        AppInfo(packageName: 'com.twitch.android.app', appName: 'Twitch'),
        AppInfo(packageName: 'com.linkedin.android', appName: 'LinkedIn'),
        AppInfo(packageName: 'com.pinterest', appName: 'Pinterest'),
        AppInfo(packageName: 'com.king.candycrushsaga', appName: 'Candy Crush'),
      ];
}
