import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_info.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/datasources/local_storage.dart';
import 'storage_provider.dart';

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final installed = await AndroidBridge.getInstalledApps();
  final storage = ref.read(storageProvider);
  final locked = storage.getLockedApps();
  final lockedPackages = {for (var a in locked) a.packageName: a};

  return installed.map((app) {
    final lockedApp = lockedPackages[app.packageName];
    if (lockedApp != null) {
      return AppInfo(
        packageName: app.packageName,
        appName: app.appName,
        isSystemApp: app.isSystemApp,
        isLocked: lockedApp.isLocked,
        totalAttempts: lockedApp.totalAttempts,
        totalOpens: lockedApp.totalOpens,
        totalResisted: lockedApp.totalResisted,
      );
    }
    return app;
  }).toList()
    ..sort((a, b) => a.appName.compareTo(b.appName));
});

class LockedAppsNotifier extends StateNotifier<List<AppInfo>> {
  final LocalStorage _storage;

  LockedAppsNotifier(this._storage) : super(_storage.getLockedApps());

  Future<void> toggleLock(String packageName, String appName) async {
    final existing = state.indexWhere((a) => a.packageName == packageName);
    List<AppInfo> updated;
    if (existing >= 0) {
      final app = state[existing];
      if (app.isLocked) {
        updated = state.where((a) => a.packageName != packageName).toList();
      } else {
        updated = [
          ...state.sublist(0, existing),
          app.copyWith(isLocked: true),
          ...state.sublist(existing + 1),
        ];
      }
    } else {
      updated = [
        ...state,
        AppInfo(packageName: packageName, appName: appName, isLocked: true),
      ];
    }
    state = updated;
    await _storage.saveLockedApps(updated);
    await AndroidBridge.updateLockedPackages(
      updated.where((a) => a.isLocked).map((a) => a.packageName).toList(),
    );
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

  Future<void> recordAttempt(String packageName, bool opened) async {
    final idx = state.indexWhere((a) => a.packageName == packageName);
    if (idx < 0) return;
    final app = state[idx];
    final updated = List<AppInfo>.from(state);
    updated[idx] = AppInfo(
      packageName: app.packageName,
      appName: app.appName,
      isSystemApp: app.isSystemApp,
      isLocked: app.isLocked,
      totalAttempts: app.totalAttempts + 1,
      totalOpens: opened ? app.totalOpens + 1 : app.totalOpens,
      totalResisted: opened ? app.totalResisted : app.totalResisted + 1,
    );
    state = updated;
    await _storage.saveLockedApps(updated);
  }

  List<AppInfo> get lockedApps =>
      state.where((a) => a.isLocked).toList();
}

final lockedAppsProvider =
    StateNotifierProvider<LockedAppsNotifier, List<AppInfo>>((ref) {
  return LockedAppsNotifier(ref.read(storageProvider));
});
