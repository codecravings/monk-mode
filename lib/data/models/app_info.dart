import 'dart:convert';

class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final bool isLocked;
  final int totalAttempts;
  final int totalOpens;
  final int totalResisted;
  final int emergencyPassesUsed;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.isLocked = false,
    this.totalAttempts = 0,
    this.totalOpens = 0,
    this.totalResisted = 0,
    this.emergencyPassesUsed = 0,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'isSystemApp': isSystemApp,
        'isLocked': isLocked,
        'totalAttempts': totalAttempts,
        'totalOpens': totalOpens,
        'totalResisted': totalResisted,
        'emergencyPassesUsed': emergencyPassesUsed,
      };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        isSystemApp: json['isSystemApp'] as bool? ?? false,
        isLocked: json['isLocked'] as bool? ?? false,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        totalOpens: json['totalOpens'] as int? ?? 0,
        totalResisted: json['totalResisted'] as int? ?? 0,
        emergencyPassesUsed: json['emergencyPassesUsed'] as int? ?? 0,
      );

  static List<AppInfo> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => AppInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<AppInfo> apps) =>
      jsonEncode(apps.map((a) => a.toJson()).toList());

  AppInfo copyWith({
    String? appName,
    bool? isLocked,
    int? totalAttempts,
    int? totalOpens,
    int? totalResisted,
    int? emergencyPassesUsed,
  }) =>
      AppInfo(
        packageName: packageName,
        appName: appName ?? this.appName,
        isSystemApp: isSystemApp,
        isLocked: isLocked ?? this.isLocked,
        totalAttempts: totalAttempts ?? this.totalAttempts,
        totalOpens: totalOpens ?? this.totalOpens,
        totalResisted: totalResisted ?? this.totalResisted,
        emergencyPassesUsed:
            emergencyPassesUsed ?? this.emergencyPassesUsed,
      );
}
