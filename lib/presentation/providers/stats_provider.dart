import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_stats.dart';
import '../../data/models/usage_record.dart';
import '../../data/datasources/local_storage.dart';
import 'storage_provider.dart';

class StatsNotifier extends StateNotifier<UserStats> {
  final LocalStorage _storage;

  StatsNotifier(this._storage) : super(_storage.getUserStats()) {
    _ensureMockData();
  }

  void _ensureMockData() {
    if (state.totalTemptationsResisted == 0 &&
        state.totalActualOpens == 0) {
      _seedMockHistory();
    }
  }

  void _seedMockHistory() {
    final now = DateTime.now();
    final records = <String, DailyRecord>{};
    for (int i = 6; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final resisted = 5 + (i * 2) % 7;
      final opened = 1 + i % 3;
      records[key] = DailyRecord(
        dateKey: key,
        temptationsResisted: resisted,
        appsOpened: opened,
      );
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final updated = state.copyWith(
      currentStreak: 3,
      bestStreak: 8,
      totalTemptationsResisted: 34,
      totalActualOpens: 12,
      lastStreakDate: yesterday,
      dailyRecords: records,
    );
    state = updated;
    _storage.saveUserStats(updated);
  }

  Future<void> recordResisted() async {
    final today = state.todayRecord;
    final updatedRecord = today.copyWith(
      temptationsResisted: today.temptationsResisted + 1,
    );
    final updated = _updateStreak(state.copyWith(
      totalTemptationsResisted: state.totalTemptationsResisted + 1,
      dailyRecords: {
        ...state.dailyRecords,
        today.dateKey: updatedRecord,
      },
    ));
    state = updated;
    await _storage.saveUserStats(updated);
  }

  Future<void> recordOpened() async {
    final today = state.todayRecord;
    final updatedRecord = today.copyWith(
      appsOpened: today.appsOpened + 1,
    );
    final updated = state.copyWith(
      totalActualOpens: state.totalActualOpens + 1,
      dailyRecords: {
        ...state.dailyRecords,
        today.dateKey: updatedRecord,
      },
    );
    state = updated;
    await _storage.saveUserStats(updated);
  }

  Future<void> recordEmergencyPass() async {
    final today = state.todayRecord;
    final updatedRecord = today.copyWith(
      emergencyPassesUsed: today.emergencyPassesUsed + 1,
    );
    final updated = state.copyWith(
      emergencyPassesUsed: state.emergencyPassesUsed + 1,
      totalActualOpens: state.totalActualOpens + 1,
      dailyRecords: {
        ...state.dailyRecords,
        today.dateKey: updatedRecord,
      },
    );
    state = updated;
    await _storage.saveUserStats(updated);
  }

  Future<void> resetEmergencyPasses() async {
    final updated = state.copyWith(emergencyPassesUsed: 0);
    state = updated;
    await _storage.saveUserStats(updated);
  }

  UserStats _updateStreak(UserStats stats) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastDate = stats.lastStreakDate;

    if (lastDate == null) {
      final newStreak = 1;
      return stats.copyWith(
        currentStreak: newStreak,
        bestStreak: newStreak > stats.bestStreak ? newStreak : stats.bestStreak,
        lastStreakDate: today,
      );
    }

    final lastKey =
        '${lastDate.year}-${lastDate.month.toString().padLeft(2, '0')}-${lastDate.day.toString().padLeft(2, '0')}';

    if (lastKey == todayKey) return stats;

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final newStreak = lastKey == yesterdayKey
        ? stats.currentStreak + 1
        : 1;

    return stats.copyWith(
      currentStreak: newStreak,
      bestStreak:
          newStreak > stats.bestStreak ? newStreak : stats.bestStreak,
      lastStreakDate: today,
    );
  }

  List<UsageRecord> getRecentRecords(String packageName, {int days = 7}) {
    final records = _storage.getUsageRecords();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records
        .where((r) =>
            r.packageName == packageName && r.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getLastSessionMinutes(String packageName) {
    final records = getRecentRecords(packageName);
    final opened = records.where((r) => r.outcome == AccessOutcome.opened);
    if (opened.isEmpty) return 23 + (packageName.length % 40);
    return opened.first.sessionMinutes ?? 23;
  }

  int getWeeklyOpenCount(String packageName) {
    final records = getRecentRecords(packageName);
    return records.where((r) => r.outcome == AccessOutcome.opened).length;
  }

  int getWeeklyHours(String packageName) {
    final opens = getWeeklyOpenCount(packageName);
    return ((opens * 35) / 60).ceil();
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, UserStats>((ref) {
  return StatsNotifier(ref.read(storageProvider));
});
