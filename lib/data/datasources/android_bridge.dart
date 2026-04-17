import 'package:flutter/services.dart';
import '../models/app_info.dart';

class AppUsageStats {
  final bool granted;
  final int totalMinutes;
  final int openCount;
  final int lastOpenTimestamp; // ms epoch; 0 = none
  final int lastSessionMinutes;
  final int avgSessionMinutes;

  const AppUsageStats({
    required this.granted,
    required this.totalMinutes,
    required this.openCount,
    required this.lastOpenTimestamp,
    required this.lastSessionMinutes,
    required this.avgSessionMinutes,
  });

  static const empty = AppUsageStats(
    granted: false,
    totalMinutes: 0,
    openCount: 0,
    lastOpenTimestamp: 0,
    lastSessionMinutes: 0,
    avgSessionMinutes: 0,
  );

  bool get hasData => granted && (totalMinutes > 0 || openCount > 0);
}

class AndroidBridge {
  static const _channel = MethodChannel('com.monkmode.app/bridge');

  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return const [];
      return result.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return AppInfo(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          isSystemApp: map['isSystemApp'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return const [];
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

  static Future<bool> isDefaultLauncher() async {
    try {
      return await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDefaultLauncher() async {
    try {
      await _channel.invokeMethod('requestDefaultLauncher');
    } catch (_) {}
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  static Future<AppUsageStats> getAppUsageStats(
    String packageName, {
    DateTime? start,
    DateTime? end,
  }) async {
    final startMs = (start ??
            DateTime.now().subtract(const Duration(days: 7)))
        .millisecondsSinceEpoch;
    final endMs = (end ?? DateTime.now()).millisecondsSinceEpoch;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getAppUsageStats',
        {
          'packageName': packageName,
          'start': startMs,
          'end': endMs,
        },
      );
      if (result == null) return AppUsageStats.empty;
      final m = Map<String, dynamic>.from(result);
      return AppUsageStats(
        granted: m['granted'] as bool? ?? false,
        totalMinutes: (m['totalMinutes'] as num?)?.toInt() ?? 0,
        openCount: (m['openCount'] as num?)?.toInt() ?? 0,
        lastOpenTimestamp: (m['lastOpenTimestamp'] as num?)?.toInt() ?? 0,
        lastSessionMinutes:
            (m['lastSessionMinutes'] as num?)?.toInt() ?? 0,
        avgSessionMinutes: (m['avgSessionMinutes'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return AppUsageStats.empty;
    }
  }

  static Future<bool> launchApp(String packageName) async {
    try {
      final ok = await _channel
          .invokeMethod<bool>('launchApp', {'packageName': packageName});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateLockedPackages(List<String> packages) async {
    try {
      await _channel
          .invokeMethod('updateLockedPackages', {'packages': packages});
    } catch (_) {}
  }
}
