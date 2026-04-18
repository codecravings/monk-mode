# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                # install deps
flutter analyze                # lint (flutter_lints recommended set)
flutter test                   # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter run                    # debug on attached device
flutter build apk --release    # release APK (~52MB)
flutter install                # push build to attached device
```

The app **cannot run on emulators** — AccessibilityService and default-launcher behaviour require a physical Android device.

## Architecture

Flutter + Kotlin Android launcher/discipline app. UI is pure Flutter; interception and system queries live on the native side and are bridged through a single MethodChannel.

### Layering (Clean-ish, no codegen)

- `lib/core/` — theme, router (GoRouter), constants
- `lib/data/models/` — plain Dart + JSON (`toJsonString` / `fromJsonString`); no freezed/json_serializable
- `lib/data/datasources/` — `LocalStorage` (SharedPreferences wrapper), `AndroidBridge` (MethodChannel), `WallpaperService`
- `lib/presentation/providers/` — Riverpod `StateNotifier`s for apps, stats, settings, permissions, access_flow
- `lib/presentation/screens/` + `widgets/`
- `lib/domain/` — **empty placeholder dirs**; the repository interfaces were never filled in. Don't add files here unless expanding the architecture on purpose.

`main.dart` bootstraps a `ProviderScope` that **overrides `storageProvider`** with the async-created `LocalStorage` — this is why most providers can `ref.read(storageProvider)` synchronously. On `AppLifecycleState.resumed` it refreshes permissions, runs `rolloverIfNeeded` on stats, and invalidates the installed-apps cache.

### The intercept flow (critical to understand)

1. User taps a locked app from anywhere (recents, notification, another launcher).
2. `MonkModeAccessibilityService` sees `TYPE_WINDOW_STATE_CHANGED`, checks the target package against the locked set, and 3-second-debounces repeats.
3. It launches `InterceptActivity` (transparent, no-history trampoline).
4. `InterceptActivity` starts `MainActivity` with a `monkmode://access-flow/why?...` deep link carrying `packageName` + `appName`.
5. Flutter GoRouter opens the 4-screen gauntlet: `why → regret → pain → countdown`, then either launches the real app via `AndroidBridge.launchApp` or records a resist.

### Locked-packages sync (easy to break)

The locked list lives in **two places** and must be kept in sync:

| Side | Prefs scope | Key | Format |
|---|---|---|---|
| Flutter | default SharedPreferences | `locked_apps` | JSON list of `AppInfo` |
| Native  | `monk_mode_native` prefs | `locked_packages` | `StringSet` of package names |

`LockedAppsNotifier.toggleLock` writes the Flutter side, then calls `AndroidBridge.updateLockedPackages(...)` which writes the native side. Any new code that mutates the locked list **must** go through this path — `MonkModeAccessibilityService` only reads the native `StringSet`.

### Native bridge surface

`MethodChannel('com.monkmode.app/bridge')` methods (implemented in `MainActivity.kt`, wrapped by `AndroidBridge`):
`getInstalledApps`, `launchApp`, `updateLockedPackages`, `isAccessibilityEnabled` / `openAccessibilitySettings`, `isUsageStatsPermissionGranted` / `openUsageStatsSettings`, `isDefaultLauncher` / `requestDefaultLauncher`, `isIgnoringBatteryOptimizations` / `openBatteryOptimizationSettings`, `getAppUsageStats` (per-package, time-bounded, via `UsageStatsManager.queryEvents` — filters bogus >8h sessions).

### Stats & streak rollover

`StatsNotifier` holds `UserStats` with a `dailyRecords` map and a `lastEvaluatedDateKey`. `_rolloverIfNeeded` walks every day from the last evaluation up to today, promoting monk days to streak increments and resetting on non-monk days. It runs on `StatsNotifier` construction and on app resume. `displayStreak` adds `+1` only if today already qualifies. `UsageRecord`s are capped at 500 entries in `LocalStorage.saveUsageRecords`.

### Wallpaper modes

`SettingsModel.wallpaperMode` is `full | dim | blur | custom | black`. Custom images go through `WallpaperService.pickFromGallery`, which copies into app documents as `custom_wallpaper.img` (single slot, overwritten each pick). `customWallpaperPath` uses a `_kSentinel` in `copyWith` so it can be explicitly cleared to `null`.

### AndroidManifest anchors

`MainActivity` declares both `CATEGORY.LAUNCHER` (normal app entry) and `CATEGORY.HOME` (default-launcher capability) intent filters, plus a `monkmode://` scheme for the intercept deep link. `launchMode="singleTask"` keeps the home-button and deep-link flows on the same task. `BootReceiver` re-hydrates state after reboot / `MY_PACKAGE_REPLACED`.
