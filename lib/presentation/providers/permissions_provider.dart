import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/android_bridge.dart';

class PermissionsState {
  final bool accessibility;
  final bool usageStats;
  final bool defaultLauncher;
  final bool batteryOptimizationIgnored;
  final bool loaded;

  const PermissionsState({
    this.accessibility = false,
    this.usageStats = false,
    this.defaultLauncher = false,
    this.batteryOptimizationIgnored = false,
    this.loaded = false,
  });

  bool get allCoreGranted => accessibility && usageStats && defaultLauncher;

  PermissionsState copyWith({
    bool? accessibility,
    bool? usageStats,
    bool? defaultLauncher,
    bool? batteryOptimizationIgnored,
    bool? loaded,
  }) =>
      PermissionsState(
        accessibility: accessibility ?? this.accessibility,
        usageStats: usageStats ?? this.usageStats,
        defaultLauncher: defaultLauncher ?? this.defaultLauncher,
        batteryOptimizationIgnored:
            batteryOptimizationIgnored ?? this.batteryOptimizationIgnored,
        loaded: loaded ?? this.loaded,
      );
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(const PermissionsState()) {
    refresh();
  }

  Future<void> refresh() async {
    final results = await Future.wait([
      AndroidBridge.isAccessibilityEnabled(),
      AndroidBridge.isUsageStatsPermissionGranted(),
      AndroidBridge.isDefaultLauncher(),
      AndroidBridge.isIgnoringBatteryOptimizations(),
    ]);
    if (!mounted) return;
    state = PermissionsState(
      accessibility: results[0],
      usageStats: results[1],
      defaultLauncher: results[2],
      batteryOptimizationIgnored: results[3],
      loaded: true,
    );
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});
