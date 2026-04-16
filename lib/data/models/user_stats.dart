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
  int temptationsResisted;
  int appsOpened;
  int emergencyPassesUsed;

  DailyRecord({
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
  int currentStreak;
  int bestStreak;
  DateTime? lastStreakDate;
  int emergencyPassesUsed;
  int totalTemptationsResisted;
  int totalActualOpens;
  Map<String, DailyRecord> dailyRecords;

  UserStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastStreakDate,
    this.emergencyPassesUsed = 0,
    this.totalTemptationsResisted = 0,
    this.totalActualOpens = 0,
    Map<String, DailyRecord>? dailyRecords,
  }) : dailyRecords = dailyRecords ?? {};

  int get emergencyPassesRemaining =>
      (3 - emergencyPassesUsed).clamp(0, 3);

  DailyRecord get todayRecord {
    final key = _todayKey();
    return dailyRecords.putIfAbsent(key, () => DailyRecord(dateKey: key));
  }

  int get todayTemptationsResisted => todayRecord.temptationsResisted;
  int get todayAppsOpened => todayRecord.appsOpened;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get weeklyMinutesWasted {
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final record = dailyRecords[key];
      if (record != null) {
        total += record.appsOpened * 35;
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'emergencyPassesUsed': emergencyPassesUsed,
        'totalTemptationsResisted': totalTemptationsResisted,
        'totalActualOpens': totalActualOpens,
        'dailyRecords': dailyRecords
            .map((k, v) => MapEntry(k, v.toJson())),
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
    DateTime? lastStreakDate,
    int? emergencyPassesUsed,
    int? totalTemptationsResisted,
    int? totalActualOpens,
    Map<String, DailyRecord>? dailyRecords,
  }) =>
      UserStats(
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastStreakDate: lastStreakDate ?? this.lastStreakDate,
        emergencyPassesUsed: emergencyPassesUsed ?? this.emergencyPassesUsed,
        totalTemptationsResisted:
            totalTemptationsResisted ?? this.totalTemptationsResisted,
        totalActualOpens: totalActualOpens ?? this.totalActualOpens,
        dailyRecords: dailyRecords ?? Map.from(this.dailyRecords),
      );
}
