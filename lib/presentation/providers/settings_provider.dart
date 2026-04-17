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

  Future<void> setAccessibilityGranted(bool value) =>
      update(state.copyWith(accessibilityGranted: value));

  Future<void> setUsageStatsGranted(bool value) =>
      update(state.copyWith(usageStatsGranted: value));

  Future<void> resetEmergencyPasses() async {
    final stats = _storage.getUserStats();
    final updated = stats.copyWith(emergencyPassesUsed: 0);
    await _storage.saveUserStats(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.read(storageProvider));
});
