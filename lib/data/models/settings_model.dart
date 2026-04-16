import 'dart:convert';

class SettingsModel {
  final int countdownSeconds;
  final int regretIntensity;
  final bool brutalQuotesOnly;
  final int maxEmergencyPasses;
  final bool accessibilityGranted;
  final bool usageStatsGranted;

  const SettingsModel({
    this.countdownSeconds = 10,
    this.regretIntensity = 3,
    this.brutalQuotesOnly = false,
    this.maxEmergencyPasses = 3,
    this.accessibilityGranted = false,
    this.usageStatsGranted = false,
  });

  Map<String, dynamic> toJson() => {
        'countdownSeconds': countdownSeconds,
        'regretIntensity': regretIntensity,
        'brutalQuotesOnly': brutalQuotesOnly,
        'maxEmergencyPasses': maxEmergencyPasses,
        'accessibilityGranted': accessibilityGranted,
        'usageStatsGranted': usageStatsGranted,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        countdownSeconds: json['countdownSeconds'] as int? ?? 10,
        regretIntensity: json['regretIntensity'] as int? ?? 3,
        brutalQuotesOnly: json['brutalQuotesOnly'] as bool? ?? false,
        maxEmergencyPasses: json['maxEmergencyPasses'] as int? ?? 3,
        accessibilityGranted: json['accessibilityGranted'] as bool? ?? false,
        usageStatsGranted: json['usageStatsGranted'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SettingsModel.fromJsonString(String str) =>
      SettingsModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  SettingsModel copyWith({
    int? countdownSeconds,
    int? regretIntensity,
    bool? brutalQuotesOnly,
    int? maxEmergencyPasses,
    bool? accessibilityGranted,
    bool? usageStatsGranted,
  }) =>
      SettingsModel(
        countdownSeconds: countdownSeconds ?? this.countdownSeconds,
        regretIntensity: regretIntensity ?? this.regretIntensity,
        brutalQuotesOnly: brutalQuotesOnly ?? this.brutalQuotesOnly,
        maxEmergencyPasses: maxEmergencyPasses ?? this.maxEmergencyPasses,
        accessibilityGranted: accessibilityGranted ?? this.accessibilityGranted,
        usageStatsGranted: usageStatsGranted ?? this.usageStatsGranted,
      );
}
