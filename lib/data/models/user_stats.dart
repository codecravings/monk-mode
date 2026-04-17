import 'dart:convert';

enum DailyScore { monk, slipping, lost }

extension DailyScoreLabel on DailyScore {
  String get label {
    switch (this) {
      case DailyScore.monk:
        return 'Monk';
      case DailyScore.slipping:
        return 'Slipping';
      case DailyScore.lost:
        return 'Lost';
    }
  }

  String get emoji {
    switch (this) {
      case DailyScore.monk:
        return '🟢';
      case DailyScore.slipping:
        return '🟡';
      case DailyScore.lost:
        return '🔴';
    }
  }
}

class DailyRecord {
  final String dateKey;
  final int temptationsResisted;
  final int appsOpened;
  final int emergencyPassesUsed;

  const DailyRecord({
    required this.dateKey,
    this.temptationsResisted = 0,
    this.appsOpened = 0,
    this.emergencyPassesUsed = 0,
  });

  DailyScore get score {
    final total = temptationsResisted + appsOpened;
    if (total == 0) return DailyScore.monk;
    final resistRatio = temptationsResisted / total;
    if (resistRatio >= 0.7) return DailyScore.monk;
    if (resistRatio >= 0.4) return DailyScore.slipping;
    return DailyScore.lost;
  }

  /// A "monk day" for streak purposes.
  /// Rules: at least one interaction (resist or open), and resists >= non-EP opens.
  /// A day with zero interactions counts as monk (nothing happened = neutral pass).
  bool get isMonkDay {
    if (temptationsResisted == 0 && appsOpened == 0) return true;
    return temptationsResisted >= appsOpened;
  }

  DailyRecord copyWith({
    int? temptationsResisted,
    int? appsOpened,
    int? emergencyPassesUsed,
  }) =>
      DailyRecord(
        dateKey: dateKey,
        temptationsResisted:
            temptationsResisted ?? this.temptationsResisted,
        appsOpened: appsOpened ?? this.appsOpened,
        emergencyPassesUsed:
            emergencyPassesUsed ?? this.emergencyPassesUsed,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'temptationsResisted': temptationsResisted,
        'appsOpened': appsOpened,
        'emergencyPassesUsed': emergencyPassesUsed,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        dateKey: json['dateKey'] as String,
        temptationsResisted: json['temptationsResisted'] as int? ?? 0,
        appsOpened: json['appsOpened'] as int? ?? 0,
        emergencyPassesUsed: json['emergencyPassesUsed'] as int? ?? 0,
      );
}

class UserStats {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastStreakDate;
  final String lastEvaluatedDateKey; // last day we ran streak rollover
  final int emergencyPassesUsed;
  final int totalTemptationsResisted;
  final int totalActualOpens;
  final Map<String, DailyRecord> dailyRecords;

  const UserStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastStreakDate,
    this.lastEvaluatedDateKey = '',
    this.emergencyPassesUsed = 0,
    this.totalTemptationsResisted = 0,
    this.totalActualOpens = 0,
    this.dailyRecords = const {},
  });

  int get emergencyPassesRemaining =>
      (3 - emergencyPassesUsed).clamp(0, 3);

  static String dateKeyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayKey() => dateKeyFor(DateTime.now());

  DailyRecord get todayRecord =>
      dailyRecords[todayKey()] ?? DailyRecord(dateKey: todayKey());

  int get todayTemptationsResisted => todayRecord.temptationsResisted;
  int get todayAppsOpened => todayRecord.appsOpened;

  /// Real minutes wasted this week, computed from opens × average session.
  /// Callers pass the average session derived from UsageStats; if none, falls
  /// back to 0 rather than a fake constant.
  int weeklyMinutesWastedWithAvg(int avgSessionMinutes) {
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = dateKeyFor(day);
      final r = dailyRecords[key];
      if (r != null) total += r.appsOpened * avgSessionMinutes;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'lastEvaluatedDateKey': lastEvaluatedDateKey,
        'emergencyPassesUsed': emergencyPassesUsed,
        'totalTemptationsResisted': totalTemptationsResisted,
        'totalActualOpens': totalActualOpens,
        'dailyRecords':
            dailyRecords.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final records = <String, DailyRecord>{};
    if (json['dailyRecords'] != null) {
      final raw = json['dailyRecords'] as Map<String, dynamic>;
      raw.forEach((k, v) {
        records[k] = DailyRecord.fromJson(v as Map<String, dynamic>);
      });
    }
    return UserStats(
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastStreakDate: json['lastStreakDate'] != null
          ? DateTime.parse(json['lastStreakDate'] as String)
          : null,
      lastEvaluatedDateKey:
          json['lastEvaluatedDateKey'] as String? ?? '',
      emergencyPassesUsed: json['emergencyPassesUsed'] as int? ?? 0,
      totalTemptationsResisted:
          json['totalTemptationsResisted'] as int? ?? 0,
      totalActualOpens: json['totalActualOpens'] as int? ?? 0,
      dailyRecords: records,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserStats.fromJsonString(String str) =>
      UserStats.fromJson(jsonDecode(str) as Map<String, dynamic>);

  UserStats copyWith({
    int? currentStreak,
    int? bestStreak,
    Object? lastStreakDate = _keep,
    String? lastEvaluatedDateKey,
    int? emergencyPassesUsed,
    int? totalTemptationsResisted,
    int? totalActualOpens,
    Map<String, DailyRecord>? dailyRecords,
  }) =>
      UserStats(
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastStreakDate: lastStreakDate == _keep
            ? this.lastStreakDate
            : lastStreakDate as DateTime?,
        lastEvaluatedDateKey:
            lastEvaluatedDateKey ?? this.lastEvaluatedDateKey,
        emergencyPassesUsed:
            emergencyPassesUsed ?? this.emergencyPassesUsed,
        totalTemptationsResisted:
            totalTemptationsResisted ?? this.totalTemptationsResisted,
        totalActualOpens: totalActualOpens ?? this.totalActualOpens,
        dailyRecords: dailyRecords ?? Map.from(this.dailyRecords),
      );
}

const _keep = Object();
