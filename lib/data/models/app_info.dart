import 'dart:convert';

class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  bool isLocked;
  int totalAttempts;
  int totalOpens;
  int totalResisted;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.isLocked = false,
    this.totalAttempts = 0,
    this.totalOpens = 0,
    this.totalResisted = 0,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'isSystemApp': isSystemApp,
        'isLocked': isLocked,
        'totalAttempts': totalAttempts,
        'totalOpens': totalOpens,
        'totalResisted': totalResisted,
      };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        isSystemApp: json['isSystemApp'] as bool? ?? false,
        isLocked: json['isLocked'] as bool? ?? false,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        totalOpens: json['totalOpens'] as int? ?? 0,
        totalResisted: json['totalResisted'] as int? ?? 0,
      );

  static List<AppInfo> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => AppInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<AppInfo> apps) =>
      jsonEncode(apps.map((a) => a.toJson()).toList());

  AppInfo copyWith({bool? isLocked}) => AppInfo(
        packageName: packageName,
        appName: appName,
        isSystemApp: isSystemApp,
        isLocked: isLocked ?? this.isLocked,
        totalAttempts: totalAttempts,
        totalOpens: totalOpens,
        totalResisted: totalResisted,
      );
}
