import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_info.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/datasources/local_storage.dart';
import 'storage_provider.dart';

/// All installed apps on the device, merged with lock/stat state from storage.
/// Re-reads on ref.invalidate.
final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final installed = await AndroidBridge.getInstalledApps();
  final storage = ref.read(storageProvider);
  final saved = storage.getLockedApps();
  final savedByPkg = {for (final a in saved) a.packageName: a};

  final merged = installed.map((app) {
    final s = savedByPkg[app.packageName];
    if (s == null) return app;
    return app.copyWith(
      appName: app.appName, // keep live label
      isLocked: s.isLocked,
      totalAttempts: s.totalAttempts,
      totalOpens: s.totalOpens,
      totalResisted: s.totalResisted,
      emergencyPassesUsed: s.emergencyPassesUsed,
    );
  }).toList()
    ..sort((a, b) =>
        a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
  return merged;
});

/// Visible apps for the Monk Mode launcher drawer — excludes locked apps.
final visibleAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final all = await ref.watch(installedAppsProvider.future);
  return all.where((a) => !a.isLocked).toList();
});

/// Just the locked apps.
final lockedAppListProvider = FutureProvider<List<AppInfo>>((ref) async {
  final all = await ref.watch(installedAppsProvider.future);
  return all.where((a) => a.isLocked).toList();
});

class LockedAppsNotifier extends StateNotifier<List<AppInfo>> {
  final LocalStorage _storage;
  final Ref _ref;

  LockedAppsNotifier(this._storage, this._ref)
      : super(_storage.getLockedApps());

  Future<void> toggleLock(String packageName, String appName) async {
    final idx = state.indexWhere((a) => a.packageName == packageName);
    List<AppInfo> updated;
    if (idx >= 0) {
      final app = state[idx];
      if (app.isLocked) {
        // Remove from list entirely when unlocking (stats zeroed)
        updated = state.where((a) => a.packageName != packageName).toList();
      } else {
        updated = [
          ...state.sublist(0, idx),
          app.copyWith(isLocked: true),
          ...state.sublist(idx + 1),
        ];
      }
    } else {
      updated = [
        ...state,
        AppInfo(
            packageName: packageName, appName: appName, isLocked: true),
      ];
    }
    state = updated;
    await _storage.saveLockedApps(updated);
    await AndroidBridge.updateLockedPackages(
      updated.where((a) => a.isLocked).map((a) => a.packageName).toList(),
    );
    _ref.invalidate(installedAppsProvider);
  }

  bool isLocked(String packageName) =>
      state.any((a) => a.packageName == packageName && a.isLocked);

  AppInfo? getApp(String packageName) {
    try {
      return state.firstWhere((a) => a.packageName == packageName);
    } catch (_) {
      return null;
    }
  }

  Future<void> recordAttempt(
    String packageName, {
    required bool opened,
    bool usedEmergencyPass = false,
  }) async {
    final idx = state.indexWhere((a) => a.packageName == packageName);
    if (idx < 0) return;
    final app = state[idx];
    final updated = List<AppInfo>.from(state);
    updated[idx] = app.copyWith(
      totalAttempts: app.totalAttempts + 1,
      totalOpens: opened ? app.totalOpens + 1 : app.totalOpens,
      totalResisted: opened ? app.totalResisted : app.totalResisted + 1,
      emergencyPassesUsed: usedEmergencyPass
          ? app.emergencyPassesUsed + 1
          : app.emergencyPassesUsed,
    );
    state = updated;
    await _storage.saveLockedApps(updated);
    _ref.invalidate(installedAppsProvider);
  }

  Future<void> reset() async {
    final zeroed = state
        .map((a) => a.copyWith(
              totalAttempts: 0,
              totalOpens: 0,
              totalResisted: 0,
              emergencyPassesUsed: 0,
            ))
        .toList();
    state = zeroed;
    await _storage.saveLockedApps(zeroed);
    _ref.invalidate(installedAppsProvider);
  }

  List<AppInfo> get lockedApps =>
      state.where((a) => a.isLocked).toList();
}

final lockedAppsProvider =
    StateNotifierProvider<LockedAppsNotifier, List<AppInfo>>((ref) {
  return LockedAppsNotifier(ref.read(storageProvider), ref);
});

/// Real per-app usage from Android UsageStatsManager.
/// Returns AppUsageStats.empty (granted: false) if permission not granted.
final appUsageProvider = FutureProvider.family
    .autoDispose<AppUsageStats, String>((ref, packageName) async {
  if (packageName.isEmpty) return AppUsageStats.empty;
  return AndroidBridge.getAppUsageStats(packageName);
});
