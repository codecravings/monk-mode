import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_stats.dart';
import '../../data/models/usage_record.dart';
import '../../data/datasources/local_storage.dart';
import 'storage_provider.dart';

class StatsNotifier extends StateNotifier<UserStats> {
  final LocalStorage _storage;

  StatsNotifier(this._storage) : super(_storage.getUserStats()) {
    _rolloverIfNeeded();
  }

  // ─── Day rollover (runs on init + can be triggered on app resume) ───────
  Future<void> rolloverIfNeeded() async => _rolloverIfNeeded();

  Future<void> _rolloverIfNeeded() async {
    final todayKey = UserStats.todayKey();
    if (state.lastEvaluatedDateKey == todayKey) return;

    // First-ever evaluation: nothing to roll forward, just anchor today.
    if (state.lastEvaluatedDateKey.isEmpty) {
      final updated = state.copyWith(lastEvaluatedDateKey: todayKey);
      state = updated;
      await _storage.saveUserStats(updated);
      return;
    }

    // Walk every day from (lastEvaluated + 1) through yesterday inclusive.
    final lastDate = _parseDateKey(state.lastEvaluatedDateKey);
    if (lastDate == null) {
      final updated = state.copyWith(lastEvaluatedDateKey: todayKey);
      state = updated;
      await _storage.saveUserStats(updated);
      return;
    }

    var cursor = DateTime(lastDate.year, lastDate.month, lastDate.day)
        .add(const Duration(days: 1));
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day);

    int currentStreak = state.currentStreak;
    int bestStreak = state.bestStreak;
    DateTime? lastStreakDate = state.lastStreakDate;

    while (cursor.isBefore(todayStart)) {
      final key = UserStats.dateKeyFor(cursor);
      final record = state.dailyRecords[key] ?? DailyRecord(dateKey: key);
      if (record.isMonkDay) {
        currentStreak += 1;
        lastStreakDate = cursor;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    final updated = state.copyWith(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      lastStreakDate: lastStreakDate,
      lastEvaluatedDateKey: todayKey,
    );
    state = updated;
    await _storage.saveUserStats(updated);
  }

  DateTime? _parseDateKey(String k) {
    try {
      final parts = k.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  /// The "live" streak shown to the user — finalized streak +1 if today is
  /// already a monk day (at least one resist so far and non-bad ratio).
  int get displayStreak {
    final today = state.todayRecord;
    final todayCounts = today.temptationsResisted > 0 && today.isMonkDay;
    return state.currentStreak + (todayCounts ? 1 : 0);
  }

  // ─── Event recording ─────────────────────────────────────────────────────
  Future<void> recordResisted({String? packageName, String? appName}) async {
    await _rolloverIfNeeded();
    final today = state.todayRecord;
    final updatedRecord = today.copyWith(
      temptationsResisted: today.temptationsResisted + 1,
    );
    final updated = state.copyWith(
      totalTemptationsResisted: state.totalTemptationsResisted + 1,
      dailyRecords: {
        ...state.dailyRecords,
        today.dateKey: updatedRecord,
      },
    );
    state = updated;
    await _storage.saveUserStats(updated);
    if (packageName != null && appName != null) {
      await _storage.addUsageRecord(UsageRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        packageName: packageName,
        appName: appName,
        timestamp: DateTime.now(),
        outcome: AccessOutcome.resisted,
      ));
    }
  }

  Future<void> recordOpened({String? packageName, String? appName}) async {
    await _rolloverIfNeeded();
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
    if (packageName != null && appName != null) {
      await _storage.addUsageRecord(UsageRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        packageName: packageName,
        appName: appName,
        timestamp: DateTime.now(),
        outcome: AccessOutcome.opened,
      ));
    }
  }

  Future<void> recordEmergencyPass(
      {String? packageName, String? appName}) async {
    await _rolloverIfNeeded();
    final today = state.todayRecord;
    final updatedRecord = today.copyWith(
      emergencyPassesUsed: today.emergencyPassesUsed + 1,
      appsOpened: today.appsOpened + 1,
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
    if (packageName != null && appName != null) {
      await _storage.addUsageRecord(UsageRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        packageName: packageName,
        appName: appName,
        timestamp: DateTime.now(),
        outcome: AccessOutcome.emergencyPass,
      ));
    }
  }

  Future<void> resetEmergencyPasses() async {
    final updated = state.copyWith(emergencyPassesUsed: 0);
    state = updated;
    await _storage.saveUserStats(updated);
  }

  Future<void> resetAllStats() async {
    await _storage.resetAllStats();
    state = _storage.getUserStats();
  }

  Future<void> resetStreaks() async {
    await _storage.resetStreaks();
    state = _storage.getUserStats();
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, UserStats>((ref) {
  return StatsNotifier(ref.read(storageProvider));
});
