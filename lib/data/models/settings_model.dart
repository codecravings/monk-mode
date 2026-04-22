import 'dart:convert';

enum WallpaperMode { full, dim, blur, custom, black }

extension WallpaperModeX on WallpaperMode {
  String get label {
    switch (this) {
      case WallpaperMode.full:
        return 'Stylized';
      case WallpaperMode.dim:
        return 'Dimmed';
      case WallpaperMode.blur:
        return 'Blurred';
      case WallpaperMode.custom:
        return 'Custom Image';
      case WallpaperMode.black:
        return 'Pure Black';
    }
  }
}

const Object _kSentinel = Object();

class SettingsModel {
  final int countdownSeconds;
  final int regretIntensity; // 1 = Mild, 2 = Strong, 3 = Brutal
  final bool brutalQuotesOnly;
  final int maxEmergencyPasses;
  final List<String> pinnedDockApps; // up to 3 package names
  final WallpaperMode wallpaperMode;
  final bool showStreakOnHome;
  final bool showClockOnHome;
  final String? customWallpaperPath;
  final double wallpaperDimOpacity; // 0.0–0.85
  final bool showIntentionOnHome;
  final String intention;
  final bool showScreenTimeOnHome;
  final int screenTimeBudgetMinutes; // daily screen-time budget target

  const SettingsModel({
    this.countdownSeconds = 10,
    this.regretIntensity = 3,
    this.brutalQuotesOnly = false,
    this.maxEmergencyPasses = 3,
    this.pinnedDockApps = const [],
    this.wallpaperMode = WallpaperMode.black,
    this.showStreakOnHome = true,
    this.showClockOnHome = true,
    this.customWallpaperPath,
    this.wallpaperDimOpacity = 0.0,
    this.showIntentionOnHome = false,
    this.intention = '',
    this.showScreenTimeOnHome = false,
    this.screenTimeBudgetMinutes = 120,
  });

  Map<String, dynamic> toJson() => {
        'countdownSeconds': countdownSeconds,
        'regretIntensity': regretIntensity,
        'brutalQuotesOnly': brutalQuotesOnly,
        'maxEmergencyPasses': maxEmergencyPasses,
        'pinnedDockApps': pinnedDockApps,
        'wallpaperMode': wallpaperMode.name,
        'showStreakOnHome': showStreakOnHome,
        'showClockOnHome': showClockOnHome,
        'customWallpaperPath': customWallpaperPath,
        'wallpaperDimOpacity': wallpaperDimOpacity,
        'showIntentionOnHome': showIntentionOnHome,
        'intention': intention,
        'showScreenTimeOnHome': showScreenTimeOnHome,
        'screenTimeBudgetMinutes': screenTimeBudgetMinutes,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        countdownSeconds: json['countdownSeconds'] as int? ?? 10,
        regretIntensity: json['regretIntensity'] as int? ?? 3,
        brutalQuotesOnly: json['brutalQuotesOnly'] as bool? ?? false,
        maxEmergencyPasses: json['maxEmergencyPasses'] as int? ?? 3,
        pinnedDockApps: (json['pinnedDockApps'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        wallpaperMode: WallpaperMode.values.firstWhere(
          (m) => m.name == (json['wallpaperMode'] as String?),
          orElse: () => WallpaperMode.black,
        ),
        showStreakOnHome: json['showStreakOnHome'] as bool? ?? true,
        showClockOnHome: json['showClockOnHome'] as bool? ?? true,
        customWallpaperPath: json['customWallpaperPath'] as String?,
        wallpaperDimOpacity:
            (json['wallpaperDimOpacity'] as num?)?.toDouble() ?? 0.0,
        showIntentionOnHome: json['showIntentionOnHome'] as bool? ?? false,
        intention: json['intention'] as String? ?? '',
        showScreenTimeOnHome:
            json['showScreenTimeOnHome'] as bool? ?? false,
        screenTimeBudgetMinutes:
            (json['screenTimeBudgetMinutes'] as num?)?.toInt() ?? 120,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SettingsModel.fromJsonString(String str) =>
      SettingsModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  SettingsModel copyWith({
    int? countdownSeconds,
    int? regretIntensity,
    bool? brutalQuotesOnly,
    int? maxEmergencyPasses,
    List<String>? pinnedDockApps,
    WallpaperMode? wallpaperMode,
    bool? showStreakOnHome,
    bool? showClockOnHome,
    Object? customWallpaperPath = _kSentinel,
    double? wallpaperDimOpacity,
    bool? showIntentionOnHome,
    String? intention,
    bool? showScreenTimeOnHome,
    int? screenTimeBudgetMinutes,
  }) =>
      SettingsModel(
        countdownSeconds: countdownSeconds ?? this.countdownSeconds,
        regretIntensity: regretIntensity ?? this.regretIntensity,
        brutalQuotesOnly: brutalQuotesOnly ?? this.brutalQuotesOnly,
        maxEmergencyPasses: maxEmergencyPasses ?? this.maxEmergencyPasses,
        pinnedDockApps: pinnedDockApps ?? this.pinnedDockApps,
        wallpaperMode: wallpaperMode ?? this.wallpaperMode,
        showStreakOnHome: showStreakOnHome ?? this.showStreakOnHome,
        showClockOnHome: showClockOnHome ?? this.showClockOnHome,
        customWallpaperPath: identical(customWallpaperPath, _kSentinel)
            ? this.customWallpaperPath
            : customWallpaperPath as String?,
        wallpaperDimOpacity: wallpaperDimOpacity ?? this.wallpaperDimOpacity,
        showIntentionOnHome:
            showIntentionOnHome ?? this.showIntentionOnHome,
        intention: intention ?? this.intention,
        showScreenTimeOnHome:
            showScreenTimeOnHome ?? this.showScreenTimeOnHome,
        screenTimeBudgetMinutes:
            screenTimeBudgetMinutes ?? this.screenTimeBudgetMinutes,
      );
}
