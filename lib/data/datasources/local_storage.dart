import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';
import '../models/usage_record.dart';
import '../models/user_stats.dart';
import '../models/settings_model.dart';
import '../../core/constants/app_constants.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  // Apps
  List<AppInfo> getLockedApps() {
    final json = _prefs.getString(AppConstants.prefLockedApps);
    if (json == null || json.isEmpty) return [];
    return AppInfo.listFromJson(json);
  }

  Future<void> saveLockedApps(List<AppInfo> apps) async {
    await _prefs.setString(AppConstants.prefLockedApps, AppInfo.listToJson(apps));
  }

  // Stats
  UserStats getUserStats() {
    final json = _prefs.getString(AppConstants.prefUserStats);
    if (json == null || json.isEmpty) return UserStats();
    return UserStats.fromJsonString(json);
  }

  Future<void> saveUserStats(UserStats stats) async {
    await _prefs.setString(AppConstants.prefUserStats, stats.toJsonString());
  }

  // Settings
  SettingsModel getSettings() {
    final json = _prefs.getString(AppConstants.prefSettings);
    if (json == null || json.isEmpty) return const SettingsModel();
    return SettingsModel.fromJsonString(json);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _prefs.setString(AppConstants.prefSettings, settings.toJsonString());
  }

  // Usage records
  List<UsageRecord> getUsageRecords() {
    final json = _prefs.getString(AppConstants.prefUsageRecords);
    if (json == null || json.isEmpty) return [];
    return UsageRecord.listFromJson(json);
  }

  Future<void> saveUsageRecords(List<UsageRecord> records) async {
    // Keep last 500 records
    final trimmed = records.length > 500
        ? records.sublist(records.length - 500)
        : records;
    await _prefs.setString(
        AppConstants.prefUsageRecords, UsageRecord.listToJson(trimmed));
  }

  Future<void> addUsageRecord(UsageRecord record) async {
    final records = getUsageRecords();
    records.add(record);
    await saveUsageRecords(records);
  }

  bool isOnboardingDone() => _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

  Future<void> setOnboardingDone() async {
    await _prefs.setBool(AppConstants.prefOnboardingDone, true);
  }
}
