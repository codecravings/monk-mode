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
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.read(storageProvider));
});
