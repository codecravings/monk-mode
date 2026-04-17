import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings_model.dart';
import '../../data/datasources/local_storage.dart';
import 'storage_provider.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final LocalStorage _storage;

  SettingsNotifier(this._storage) : super(_storage.getSettings());

  Future<void> update(SettingsModel updated) async {
    state = updated;
    await _storage.saveSettings(updated);
  }

  Future<void> setCountdownSeconds(int seconds) =>
      update(state.copyWith(countdownSeconds: seconds.clamp(5, 30)));

  Future<void> setRegretIntensity(int intensity) =>
      update(state.copyWith(regretIntensity: intensity.clamp(1, 3)));

  Future<void> setBrutalQuotesOnly(bool value) =>
      update(state.copyWith(brutalQuotesOnly: value));

  Future<void> setWallpaperMode(WallpaperMode mode) =>
      update(state.copyWith(wallpaperMode: mode));

  Future<void> setShowStreakOnHome(bool value) =>
      update(state.copyWith(showStreakOnHome: value));

  Future<void> setCustomWallpaperPath(String? path) =>
      update(state.copyWith(customWallpaperPath: path));

  Future<void> setWallpaperDimOpacity(double opacity) =>
      update(state.copyWith(wallpaperDimOpacity: opacity.clamp(0.0, 0.85)));

  Future<void> setDockApps(List<String> packages) {
    final trimmed = packages.take(3).toList();
    return update(state.copyWith(pinnedDockApps: trimmed));
  }

  Future<void> toggleDockApp(String packageName) {
    final current = List<String>.from(state.pinnedDockApps);
    if (current.contains(packageName)) {
      current.remove(packageName);
    } else if (current.length < 3) {
      current.add(packageName);
    }
    return update(state.copyWith(pinnedDockApps: current));
  }

  Future<void> unpinDockApp(String packageName) {
    final current = List<String>.from(state.pinnedDockApps)
      ..remove(packageName);
    return update(state.copyWith(pinnedDockApps: current));
  }

  /// Replace `oldPackage` in the dock with `newPackage`, preserving slot order.
  /// If `oldPackage` is not pinned, falls back to an append (if room).
  Future<void> replaceDockApp({
    required String oldPackage,
    required String newPackage,
  }) {
    final current = List<String>.from(state.pinnedDockApps);
    final idx = current.indexOf(oldPackage);
    if (idx >= 0) {
      current[idx] = newPackage;
    } else if (current.length < 3) {
      current.add(newPackage);
    }
    return update(state.copyWith(pinnedDockApps: current));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.read(storageProvider));
});
