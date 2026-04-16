import 'dart:convert';

enum AccessReason { habit, bored, escapingWork, lonely, realNeed }

enum AccessOutcome { resisted, opened, emergencyPass }

class UsageRecord {
  final String id;
  final String packageName;
  final String appName;
  final DateTime timestamp;
  final AccessReason? reason;
  final AccessOutcome outcome;
  final int? sessionMinutes;

  UsageRecord({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.timestamp,
    this.reason,
    required this.outcome,
    this.sessionMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason?.index,
        'outcome': outcome.index,
        'sessionMinutes': sessionMinutes,
      };

  factory UsageRecord.fromJson(Map<String, dynamic> json) => UsageRecord(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        reason: json['reason'] != null
            ? AccessReason.values[json['reason'] as int]
            : null,
        outcome: AccessOutcome.values[json['outcome'] as int],
        sessionMinutes: json['sessionMinutes'] as int?,
      );

  static List<UsageRecord> listFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => UsageRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<UsageRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());
}

extension AccessReasonLabel on AccessReason {
  String get label {
    switch (this) {
      case AccessReason.habit:
        return 'Habit';
      case AccessReason.bored:
        return 'Bored';
      case AccessReason.escapingWork:
        return 'Escaping Work';
      case AccessReason.lonely:
        return 'Lonely';
      case AccessReason.realNeed:
        return 'Real Need';
    }
  }

  String get emoji {
    switch (this) {
      case AccessReason.habit:
        return '🔄';
      case AccessReason.bored:
        return '😐';
      case AccessReason.escapingWork:
        return '🏃';
      case AccessReason.lonely:
        return '😔';
      case AccessReason.realNeed:
        return '✅';
    }
  }
}
