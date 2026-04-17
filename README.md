<div align="center">

<img src="assets/monk_logo.png" width="120" alt="Monk Mode Logo" />

# Monk Mode

**Your ruthless attention guardian.**

*Not a productivity app. A discipline system. A home screen that fights back.*

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://developer.android.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00ACC1?style=flat-square)](https://riverpod.dev)
[![Launcher](https://img.shields.io/badge/Type-Default%20Launcher-8B5CF6?style=flat-square)](#the-launcher)
[![License](https://img.shields.io/badge/License-MIT-white?style=flat-square)](LICENSE)

[**GitHub**](https://github.com/codecravings/monk-mode) · [Install](#getting-started) · [Philosophy](#philosophy)

</div>

---

## What is Monk Mode?

You open Instagram for "just 5 minutes" and resurface 47 minutes later, vaguely unsatisfied. You know this pattern. You hate this pattern. You keep doing it anyway.

**Monk Mode exists to break that loop.**

It replaces your home screen. It watches the apps you flagged as distractions. And every time you reach for one, it drags you through a four-step friction gauntlet — not to block you forever, but to make you *pause and decide consciously* instead of acting on impulse. Most of the time, the pause is enough.

The app is intentionally intense. It shows you your real usage stats. It confronts you with your patterns. It counts down ten seconds. It lets you choose. Every time you walk away, your streak grows. Every time you don't, it remembers.

---

## The Launcher

Monk Mode isn't an app you open — it's your home screen.

```
                   9:41
            Thursday, April 17
          ┌──────────────────┐
          │  🔥  14 day streak │
          └──────────────────┘



            [ W ]   [ S ]   [ N ]
             WhatsApp  Spotify  Notes
                                    
             ─────   swipe up for all   ─────
```

- **Clock + date + streak** — the only things on your home screen, deliberately
- **3-app pinned dock** — tap a pinned locked app and you still hit the gauntlet
- **Swipe up** for the full app drawer
- **Long-press** anywhere for quick actions (Dashboard, Vault, Edit Dock, Settings)
- **Wallpaper modes** — *Full*, *Dim*, *Blur*, *Pure Black* — choose your level of visual quiet
- **Stats icons** top-right open the Dashboard and Settings

Because Monk Mode is set as the default launcher (Android CATEGORY_HOME), every press of the Home button lands you back on this calm, stats-first screen — not a grid of distractions.

---

## The Gauntlet

When you try to open a locked app, you don't get straight in. You pass through four screens:

**1. Why Are You Here?**
Pick your honest reason — Habit, Bored, Escaping Work, Lonely, or Real Need. No judgment, just awareness.

**2. The Regret Mirror**
Real stats, pulled from Android's UsageStatsManager. How long you stayed last time. How many times you opened it this week. How many hours it has taken from your life. Hard numbers, plainly stated.

**3. Pain Confirmation**
A rotating brutal message — *"Every tap trains weakness."* *"Your future self is watching this choice."* Two buttons: **Stay Strong 🔥** or **Open Anyway 😞**.

**4. 10-Second Countdown**
A forced wait. The timer pulses. Messages rotate: *"Urges fade when not fed."* *"10 seconds can save 1 hour."* You can still cancel. Most people do.

Every traversal — whether you resist or relent — is recorded and shapes tomorrow's Regret Mirror.

---

## Features

### Launcher
- **Home screen** with minute-aligned clock, date, and live streak pill
- **3-slot pinned dock** — tap to launch, or hit the gauntlet if the app is locked
- **Swipe-up app drawer** with search
- **Wallpaper modes** — Full / Dim / Blur / Pure Black
- **Long-press quick actions** — Dashboard, Drawer, Vault, Edit Dock, Settings
- **Default launcher integration** — CATEGORY_HOME + CATEGORY_DEFAULT intent filters

### Discipline Engine
- **Vault** — dedicated screen listing every locked app
- **App Picker** — browse every installed app and lock any of them in one tap
- **4-screen gauntlet** — Why → Regret Mirror → Pain → Countdown
- **Emergency Pass** — 3 lifetime passes for genuine emergencies. No auto-refill. Ever.
- **Real session tracking** — UsageStatsManager + UsageEvents (MOVE_TO_FOREGROUND / BACKGROUND) power the Regret Mirror
- **Accessibility fallback** — if Usage Stats is degraded, the AccessibilityService intercepts window state changes

### Stats & Streaks
- **Streak engine** with midnight rollover — walks every missed day since last evaluation, awards or breaks streaks honestly
- **Daily Score** — each day rated Monk 🟢, Slipping 🟡, or Lost 🔴 based on your choices
- **Dashboard** — time stolen this week, time saved by resisting, urges defeated, best streak
- **Weekly chart** — visual breakdown of resisted vs opened, per day, via fl_chart
- **Regret Mirror** — per-app session history, open counts, total hours lost

### Settings
- Countdown length (5 / 10 / 20 / 30 seconds)
- Wallpaper mode selector
- Show streak on home (toggle)
- Edit pinned dock
- All 4 permission tiles with live state
- Reset streaks / reset all statistics (with confirmation)

---

## How It Works

Monk Mode uses four Android permissions to do its job. Every one is opt-in. Every one stays on-device — nothing is collected, nothing is transmitted.

| Permission | Purpose |
|---|---|
| **Default Launcher** | Replaces your home screen with Monk Mode's calm, stats-first surface |
| **Accessibility Service** | Detects when a locked app opens and triggers the gauntlet |
| **Usage Stats** | Feeds real session data (duration, open count, foreground time) into the Regret Mirror |
| **Battery Optimization (ignored)** | Keeps the accessibility service alive when the OS would otherwise sleep it |

The accessibility service watches window state changes; when a locked package moves to the foreground, `InterceptActivity` relaunches Flutter straight into the gauntlet. On boot — `BOOT_COMPLETED`, `LOCKED_BOOT_COMPLETED`, and `MY_PACKAGE_REPLACED` — a `BootReceiver` reinitialises state so the launcher survives reboots and updates without missing a beat.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.41 / Dart |
| State Management | Riverpod (StateNotifierProvider, no codegen) |
| Navigation | GoRouter — `/home` is the launcher entry |
| Storage | SharedPreferences (zero codegen) |
| Charts | fl_chart |
| Animations | flutter_animate |
| Typography | Google Fonts — Space Grotesk |
| Native Bridge | MethodChannel `com.monkmode.app/bridge` (Kotlin) |
| Wallpaper FX | BackdropFilter + `ImageFilter.blur` |
| Architecture | Clean Architecture (data / domain / presentation) |

---

## Getting Started

**Prerequisites:** Flutter 3.0+, Android SDK, a physical Android device (emulators can't test Accessibility Services or default launcher behaviour properly).

```bash
# Clone
git clone https://github.com/codecravings/monk-mode.git
cd monk-mode

# Install dependencies
flutter pub get

# Run debug build on connected device
flutter run

# Build release APK
flutter build apk --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### First launch on device

1. Install and open the app — onboarding starts automatically
2. Grant the four permissions one by one:
   - **Default Launcher** → pick Monk Mode when prompted
   - **Accessibility Service** → find *Monk Mode Guard* in the list, toggle it on
   - **Usage Stats** → find Monk Mode, allow
   - **Battery Optimization** → ignore battery optimization for Monk Mode
3. Open **Vault** → **Lock Apps** → pick your distractions
4. Open **Edit Dock** in Settings → pin the 3 apps you actually use
5. Press the Home button — welcome to Monk Mode.

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Brutal messages copy, app constants
│   ├── theme/           # Dark theme, AppColors
│   └── router.dart      # GoRouter — /home is the launcher
├── data/
│   ├── datasources/     # LocalStorage, AndroidBridge (MethodChannel)
│   └── models/          # AppInfo, UsageRecord, UserStats, Settings (+ WallpaperMode)
└── presentation/
    ├── providers/        # apps, stats, settings, permissions, access flow
    ├── screens/
    │   ├── launcher_home_screen.dart    # Clock + date + streak + dock + swipe-up
    │   ├── app_drawer_screen.dart
    │   ├── dock_picker_screen.dart
    │   ├── vault_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── settings_screen.dart
    │   ├── onboarding_screen.dart
    │   ├── emergency_pass_screen.dart
    │   └── access_flow/                 # Why → Regret → Pain → Countdown
    └── widgets/          # StreakCard, StatCard, UsageChart, etc.

android/app/src/main/kotlin/com/monkmode/monk_mode/
├── MainActivity.kt                   # MethodChannel handler + launcher intent filters
├── MonkModeAccessibilityService.kt   # Window-state interceptor
├── InterceptActivity.kt              # Transparent trampoline into Flutter gauntlet
├── UsageStatsBridge.kt               # UsageEvents → Dart
└── BootReceiver.kt                   # BOOT_COMPLETED / LOCKED_BOOT_COMPLETED / MY_PACKAGE_REPLACED
```

---

## Philosophy

Most apps try to make discipline easy. Monk Mode doesn't. It makes distraction *harder* — intentionally, unapologetically. The friction is the feature.

Your home screen is the first thing you see a hundred times a day. If it's a wall of dopamine triggers, you've already lost before you opened your eyes. If it's a clock, a streak, and three honest apps — you stand a chance.

The best version of you doesn't need an easy path. It needs a clear mirror and a moment to choose.

That's what this app is.

---

<div align="center">

**[github.com/codecravings/monk-mode](https://github.com/codecravings/monk-mode)**

Built with focus, by someone who also struggles with distraction.

**[codecravings](https://github.com/codecravings)**

</div>
