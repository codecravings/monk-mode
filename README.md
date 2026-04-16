<div align="center">

<img src="assets/monk_logo.png" width="120" alt="Monk Mode Logo" />

# Monk Mode

**Your ruthless attention guardian.**

*Not a productivity app. A discipline system.*

[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://developer.android.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00ACC1?style=flat-square)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-white?style=flat-square)](LICENSE)

</div>

---

## What is Monk Mode?

We all have apps that eat our time. You open Instagram for "just 5 minutes" and surface 47 minutes later, vaguely unsatisfied. You know this pattern. You hate this pattern. You keep doing it anyway.

**Monk Mode exists to break that loop.**

It locks your chosen distraction apps and forces you through a friction gauntlet before you can open them — not to block you forever, but to make you *pause and decide consciously* instead of acting on impulse. Most of the time, that pause is enough.

The app is intentionally intense. It shows you your real usage stats, confronts you with your patterns, counts down 10 seconds, and lets you choose. Every time you walk away, your streak grows. Every time you don't, it remembers.

---

## The Gauntlet

When you try to open a locked app, you don't get straight in. You go through four screens:

**1. Why Are You Here?**
Pick your honest reason — Habit, Bored, Escaping Work, Lonely, or Real Need. No judgment, just awareness.

**2. The Regret Mirror**
Real stats. How long you stayed last time. How many times you opened it this week. How many hours it has taken from your life. Hard numbers, plainly stated.

**3. Pain Confirmation**
A rotating brutal message — *"Every tap trains weakness."* *"Your future self is watching this choice."* Two buttons: **Stay Strong 🔥** or **Open Anyway 😞**.

**4. 10-Second Countdown**
A forced wait. The timer pulses. Messages rotate: *"Urges fade when not fed."* *"10 seconds can save 1 hour."* You can still cancel. Most people do.

---

## Features

- **App Picker** — Browse all installed apps, lock any of them with one tap
- **Brutal Access Flow** — The 4-screen gauntlet described above, every single time
- **Streak System** — Tracks days of discipline. Your best streak is remembered. Breaking it hurts.
- **Daily Score** — Each day rated: Monk 🟢, Slipping 🟡, or Lost 🔴 based on your choices
- **Emergency Pass** — 3 lifetime passes for genuine emergencies. No auto-refill.
- **Dashboard** — Time stolen this week, time saved by resisting, urges defeated, streak status
- **Weekly Chart** — Visual breakdown of resisted vs opened per day
- **Settings** — Adjust countdown length, regret intensity, reset passes, manage permissions
- **Onboarding** — Guides you through enabling the Accessibility Service and Usage Stats

---

## How the Locking Works

Monk Mode uses Android's **Accessibility Service** to watch for window state changes. When a locked app's window appears, the service immediately launches the intercept flow — before you can interact with it.

Two Android permissions power this:

| Permission | Purpose |
|---|---|
| Accessibility Service | Detects when a locked app opens and triggers the gauntlet |
| Usage Stats | Feeds real session data into the Regret Mirror |

Both are opt-in. The app works in a degraded mode (with estimated stats) if you skip them, but the full experience requires both. Neither permission is used to collect or transmit any data — everything stays on your device.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.41 |
| State Management | Riverpod (StateNotifier) |
| Navigation | GoRouter |
| Storage | SharedPreferences (zero codegen) |
| Charts | fl_chart |
| Animations | flutter_animate |
| Typography | Google Fonts — Space Grotesk |
| Native Bridge | MethodChannel (Kotlin) |
| Architecture | Clean Architecture |

---

## Getting Started

**Prerequisites:** Flutter 3.0+, Android SDK, a physical Android device (emulators can't test Accessibility Services properly)

```bash
# Clone
git clone https://github.com/codecravings/monk-mode.git
cd monk-mode

# Install dependencies
flutter pub get

# Run debug build
flutter run

# Build release APK
flutter build apk --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

**First launch on device:**
1. Open the app and complete onboarding
2. Tap **Enable** next to *Accessibility Service* → find **Monk Mode Guard** in the list → toggle it on
3. Tap **Enable** next to *Usage Stats* → find Monk Mode → allow
4. Go to **Lock Apps** → pick your distractions → done

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App constants, brutal messages copy
│   ├── theme/           # Dark theme, AppColors
│   └── router.dart      # GoRouter config
├── data/
│   ├── datasources/     # LocalStorage, AndroidBridge (MethodChannel)
│   └── models/          # AppInfo, UsageRecord, UserStats, Settings
└── presentation/
    ├── providers/        # Riverpod state (apps, stats, settings, access flow)
    ├── screens/
    │   ├── access_flow/  # Why → Regret → Pain → Countdown
    │   └── ...           # Dashboard, AppPicker, Settings, etc.
    └── widgets/          # StreakCard, StatCard, UsageChart, etc.

android/app/src/main/kotlin/com/monkmode/monk_mode/
├── MainActivity.kt                   # MethodChannel handler
├── MonkModeAccessibilityService.kt   # App intercept logic
└── InterceptActivity.kt              # Transparent trampoline to Flutter
```

---

## Philosophy

Most apps try to make discipline easy. Monk Mode doesn't. It makes distraction *harder* — intentionally, unapologetically. The friction is the feature.

The best version of you doesn't need an easy path. It needs a clear mirror and a moment to choose.

That's what this app is.



<div align="center">

Built with focus, by someone who also struggles with distraction.

**[codecravings](https://github.com/codecravings)**

</div>
