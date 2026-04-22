import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/models/app_info.dart';
import '../../data/models/settings_model.dart';
import '../../data/models/user_stats.dart';
import '../providers/apps_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';

/// Premium minimal launcher home. This is the screen the user lands on every
/// time they press the Home button while Monk Mode is the default launcher.
class LauncherHomeScreen extends ConsumerStatefulWidget {
  const LauncherHomeScreen({super.key});

  @override
  ConsumerState<LauncherHomeScreen> createState() =>
      _LauncherHomeScreenState();
}

class _LauncherHomeScreenState extends ConsumerState<LauncherHomeScreen> {
  Timer? _clockTick;
  late DateTime _now;
  late String _dateKey;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _dateKey = UserStats.todayKey();
    // Tick at the top of the next minute, then every 60s.
    final msToNextMinute = (60 - _now.second) * 1000 - _now.millisecond;
    _clockTick = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) return;
      _onTick();
      _clockTick = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        _onTick();
      });
    });
  }

  void _onTick() {
    final now = DateTime.now();
    final todayKey = UserStats.todayKey();
    final dayFlipped = todayKey != _dateKey;
    setState(() {
      _now = now;
      _dateKey = todayKey;
    });
    // Re-fetch today's screen-time from UsageStatsManager so the home
    // screen's budget line stays roughly in sync while the user sits on it.
    ref.invalidate(todayScreenTimeProvider);
    if (dayFlipped) {
      // Cross-midnight: fold yesterday into the streak and rebuild with fresh
      // display values. The notifier's state change triggers the watcher in
      // build(), so no second setState is needed.
      ref.read(statsProvider.notifier).rolloverIfNeeded();
    }
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // Watch the stats state so rebuilds fire on streak changes; the notifier
    // computes the live-today-adjusted display streak.
    ref.watch(statsProvider);
    final displayStreak = ref.read(statsProvider.notifier).displayStreak;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _Wallpaper(
        mode: settings.wallpaperMode,
        customPath: settings.customWallpaperPath,
        dimOpacity: settings.wallpaperDimOpacity,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -200) {
                context.push('/app-drawer');
              }
            },
            onLongPress: () => _showQuickActions(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
              child: Column(
                children: [
                  const _TopActions(),
                  const Spacer(flex: 2),
                  if (settings.showClockOnHome)
                    _ClockBlock(
                      now: _now,
                      showStreak: settings.showStreakOnHome,
                      streak: displayStreak,
                      showIntention: settings.showIntentionOnHome,
                      intention: settings.intention,
                      onEditIntention: () => _editIntention(context),
                    )
                  else if (settings.showStreakOnHome)
                    _StreakPill(streak: displayStreak)
                        .animate()
                        .fadeIn(duration: 400.ms),
                  const Spacer(flex: 3),
                  _Dock(pinned: settings.pinnedDockApps),
                  const SizedBox(height: 10),
                  const _SwipeHint(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editIntention(BuildContext context) async {
    final current = ref.read(settingsProvider).intention;
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          "Today's intention",
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Ship the draft. Hit the gym. Read 20 pages.',
            hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.muted),
            counterStyle: GoogleFonts.spaceGrotesk(color: AppColors.muted),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
            ),
          ),
          if (current.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: Text(
                'Clear',
                style: GoogleFonts.spaceGrotesk(color: AppColors.secondary),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              'Save',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.monkGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setIntention(result);
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickTile(
                icon: Icons.bar_chart_rounded,
                label: 'Dashboard',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/dashboard');
                },
              ),
              _QuickTile(
                icon: Icons.grid_view_rounded,
                label: 'All Apps',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/app-drawer');
                },
              ),
              _QuickTile(
                icon: Icons.lock_outline,
                label: 'Vault (Locked Apps)',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/vault');
                },
              ),
              _QuickTile(
                icon: Icons.pin_drop_outlined,
                label: 'Edit Dock',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/dock-picker');
                },
              ),
              _QuickTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top status row ─────────────────────────────────────────────────────────
class _TopActions extends ConsumerWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _IconBtn(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Dashboard',
          onTap: () => context.push('/dashboard'),
        ),
        Text(
          'MONK MODE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: AppColors.muted,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        _IconBtn(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22, color: AppColors.secondary),
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ─── Clock / date / streak ──────────────────────────────────────────────────
class _ClockBlock extends StatelessWidget {
  final DateTime now;
  final bool showStreak;
  final int streak;
  final bool showIntention;
  final String intention;
  final VoidCallback onEditIntention;

  const _ClockBlock({
    required this.now,
    required this.showStreak,
    required this.streak,
    required this.showIntention,
    required this.intention,
    required this.onEditIntention,
  });

  @override
  Widget build(BuildContext context) {
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final dateStr = _formatDate(now);

    return Column(
      children: [
        Text(
          '$h:$m',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 96,
            fontWeight: FontWeight.w200,
            color: AppColors.primary,
            height: 1,
            letterSpacing: -2,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 12),
        Text(
          dateStr,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: AppColors.muted,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        if (showIntention) ...[
          const SizedBox(height: 18),
          _IntentionLine(
            intention: intention,
            onTap: onEditIntention,
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
        ],
        if (showStreak) ...[
          const SizedBox(height: 26),
          _StreakPill(streak: streak)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${weekdays[d.weekday - 1]}  ${d.day}  ${months[d.month - 1]}';
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;

  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.monk.withAlpha(40)
            : AppColors.surface.withAlpha(140),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active
              ? AppColors.monkGold.withAlpha(120)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(active ? '🔥' : '☯',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            active
                ? '$streak day${streak == 1 ? '' : 's'} clean'
                : 'Begin your streak',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.monkGold : AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Intention line (one-liner the user sets each morning) ──────────────────
class _IntentionLine extends StatelessWidget {
  final String intention;
  final VoidCallback onTap;

  const _IntentionLine({required this.intention, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final empty = intention.isEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            empty ? 'Tap to set today\'s intention' : '"$intention"',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontStyle: empty ? FontStyle.normal : FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: empty ? AppColors.muted : AppColors.secondary,
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dock ───────────────────────────────────────────────────────────────────
class _Dock extends ConsumerWidget {
  final List<String> pinned;

  const _Dock({required this.pinned});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(140),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: appsAsync.when(
        loading: () => const SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.muted,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        error: (_, __) => _emptyDock(context),
        data: (apps) {
          final byPkg = {for (final a in apps) a.packageName: a};
          final slots = List<AppInfo?>.generate(3, (i) {
            if (i >= pinned.length) return null;
            return byPkg[pinned[i]];
          });
          final allEmpty = slots.every((s) => s == null);
          if (allEmpty) return _emptyDock(context);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: slots.map((app) {
              if (app == null) {
                return _DockSlot(
                  onTap: () => context.push('/dock-picker'),
                  child: const Icon(Icons.add,
                      color: AppColors.muted, size: 22),
                );
              }
              return _DockSlot(
                onTap: () => _launch(context, ref, app),
                onLongPress: () => _unpin(context, ref, app),
                child: _DockGlyph(app: app),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _emptyDock(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dock-picker'),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'Tap to pin 3 apps to your dock',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  void _unpin(BuildContext context, WidgetRef ref, AppInfo app) {
    ref.read(settingsProvider.notifier).unpinDockApp(app.packageName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unpinned ${app.appName}',
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Edit dock',
          textColor: AppColors.monkGold,
          onPressed: () => context.push('/dock-picker'),
        ),
      ),
    );
  }

  Future<void> _launch(
      BuildContext context, WidgetRef ref, AppInfo app) async {
    if (app.isLocked) {
      context.push(
        '/access-flow/why',
        extra: {
          'packageName': app.packageName,
          'appName': app.appName,
        },
      );
      return;
    }
    final ok = await AndroidBridge.launchApp(app.packageName);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch ${app.appName}',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }
}

class _DockSlot extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const _DockSlot({
    required this.onTap,
    this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

class _DockGlyph extends StatelessWidget {
  final AppInfo app;

  const _DockGlyph({required this.app});

  @override
  Widget build(BuildContext context) {
    return Text(
      app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
      style: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/app-drawer'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.muted.withAlpha(120),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Swipe up for all apps',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Wallpaper background ───────────────────────────────────────────────────
class _Wallpaper extends StatefulWidget {
  final WallpaperMode mode;
  final String? customPath;
  final double dimOpacity;
  final Widget child;

  const _Wallpaper({
    required this.mode,
    required this.customPath,
    required this.dimOpacity,
    required this.child,
  });

  @override
  State<_Wallpaper> createState() => _WallpaperState();
}

class _WallpaperState extends State<_Wallpaper> {
  File? _customFile;

  @override
  void initState() {
    super.initState();
    _resolveCustom();
  }

  @override
  void didUpdateWidget(covariant _Wallpaper old) {
    super.didUpdateWidget(old);
    if (old.customPath != widget.customPath) _resolveCustom();
  }

  void _resolveCustom() {
    final path = widget.customPath;
    if (path == null) {
      _customFile = null;
      return;
    }
    final f = File(path);
    _customFile = f.existsSync() ? f : null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == WallpaperMode.black) {
      return Container(color: AppColors.background, child: widget.child);
    }

    Widget background = _buildBackground();
    if (widget.mode == WallpaperMode.blur) {
      background = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: background,
      );
    }

    final baseDim = widget.mode == WallpaperMode.dim ? 0.45 : 0.0;
    final effectiveDim = (baseDim + widget.dimOpacity).clamp(0.0, 0.95);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          if (effectiveDim > 0)
            Container(color: Colors.black.withValues(alpha: effectiveDim)),
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.mode == WallpaperMode.custom && _customFile != null) {
      return Image.file(
        _customFile!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return Container(
      decoration: BoxDecoration(gradient: _gradientFor(widget.mode)),
    );
  }

  LinearGradient _gradientFor(WallpaperMode mode) {
    switch (mode) {
      case WallpaperMode.full:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1117), Color(0xFF050505)],
        );
      case WallpaperMode.dim:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14161A), Color(0xFF000000)],
        );
      case WallpaperMode.blur:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A22), Color(0xFF080810)],
        );
      case WallpaperMode.custom:
      case WallpaperMode.black:
        return const LinearGradient(
          colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
        );
    }
  }
}
