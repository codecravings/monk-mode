import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/models/settings_model.dart';
import '../providers/apps_provider.dart';
import '../providers/permissions_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final perms = ref.watch(permissionsProvider);
    final permsNotifier = ref.read(permissionsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionTitle('EXPERIENCE'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _SliderTile(
                  label: 'Countdown Duration',
                  value: settings.countdownSeconds.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  unit: 's',
                  onChanged: (v) =>
                      settingsNotifier.setCountdownSeconds(v.round()),
                ),
                const Divider(height: 24),
                _SliderTile(
                  label: 'Regret Intensity',
                  value: settings.regretIntensity.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  labels: const ['Mild', 'Strong', 'Brutal'],
                  onChanged: (v) =>
                      settingsNotifier.setRegretIntensity(v.round()),
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Brutal Quotes Only',
                  subtitle: 'Show only the harshest messages',
                  value: settings.brutalQuotesOnly,
                  onChanged: settingsNotifier.setBrutalQuotesOnly,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('LAUNCHER'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.push_pin_outlined,
                  label: 'Edit Dock (${settings.pinnedDockApps.length}/3)',
                  color: AppColors.primary,
                  onTap: () => context.push('/dock-picker'),
                ),
                const Divider(height: 24),
                _WallpaperTile(
                  selected: settings.wallpaperMode,
                  onSelect: (m) =>
                      settingsNotifier.setWallpaperMode(m),
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Show Streak on Home',
                  subtitle: 'Display the monk streak pill under the clock',
                  value: settings.showStreakOnHome,
                  onChanged: settingsNotifier.setShowStreakOnHome,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('PERMISSIONS'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.home_rounded,
                  label: 'Default Launcher',
                  subtitle: 'Required to replace your home screen',
                  granted: perms.defaultLauncher,
                  onGrant: () async {
                    await AndroidBridge.requestDefaultLauncher();
                    await Future.delayed(const Duration(milliseconds: 600));
                    permsNotifier.refresh();
                  },
                ),
                const Divider(height: 24),
                _PermissionTile(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Accessibility Service',
                  subtitle: 'Intercepts locked app opens outside vault',
                  granted: perms.accessibility,
                  onGrant: () async {
                    await AndroidBridge.openAccessibilitySettings();
                  },
                ),
                const Divider(height: 24),
                _PermissionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Usage Stats',
                  subtitle: 'Powers the Regret Mirror with real data',
                  granted: perms.usageStats,
                  onGrant: () async {
                    await AndroidBridge.openUsageStatsSettings();
                  },
                ),
                const Divider(height: 24),
                _PermissionTile(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'Ignore Battery Optimization',
                  subtitle: 'Keeps the lock engine alive in background',
                  granted: perms.batteryOptimizationIgnored,
                  onGrant: () async {
                    await AndroidBridge.openBatteryOptimizationSettings();
                    await Future.delayed(const Duration(milliseconds: 600));
                    permsNotifier.refresh();
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('EMERGENCY PASSES'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manually reset emergency passes.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppColors.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use sparingly. This is your override.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _confirmResetPasses(context, ref),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    foregroundColor: AppColors.warning,
                  ),
                  child: const Text('Reset Emergency Passes'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('DATA'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset Streaks',
                  color: AppColors.warning,
                  onTap: () => _confirmResetStreaks(context, ref),
                ),
                const Divider(height: 24),
                _ActionTile(
                  icon: Icons.refresh_rounded,
                  label: 'Reset All Statistics',
                  color: AppColors.danger,
                  onTap: () => _confirmResetStats(context, ref),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('ABOUT'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monk Mode v1.0.0',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"A wise ruthless mentor guarding your attention."',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmResetPasses(BuildContext context, WidgetRef ref) {
    _confirmDialog(
      context: context,
      title: 'Reset Passes?',
      message: 'This restores all 3 emergency passes.',
      confirmLabel: 'Reset',
      confirmColor: AppColors.warning,
      onConfirm: () =>
          ref.read(statsProvider.notifier).resetEmergencyPasses(),
    );
  }

  void _confirmResetStreaks(BuildContext context, WidgetRef ref) {
    _confirmDialog(
      context: context,
      title: 'Reset Streaks?',
      message:
          'This wipes your current and best streak. Daily history stays.',
      confirmLabel: 'Reset Streaks',
      confirmColor: AppColors.warning,
      onConfirm: () => ref.read(statsProvider.notifier).resetStreaks(),
    );
  }

  void _confirmResetStats(BuildContext context, WidgetRef ref) {
    _confirmDialog(
      context: context,
      title: 'Reset All Stats?',
      message:
          'This erases your streaks, history, and per-app counters. Cannot be undone.',
      confirmLabel: 'Reset Everything',
      confirmColor: AppColors.danger,
      onConfirm: () async {
        await ref.read(statsProvider.notifier).resetAllStats();
        await ref.read(lockedAppsProvider.notifier).reset();
      },
    );
  }

  void _confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Done.',
                      style: GoogleFonts.spaceGrotesk(),
                    ),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.spaceGrotesk(color: confirmColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? unit;
  final List<String>? labels;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unit,
    this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayVal = labels != null
        ? labels![(value - min).round().clamp(0, labels!.length - 1)]
        : '${value.round()}${unit ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              displayVal,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppColors.monkGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(20),
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.border,
          inactiveThumbColor: AppColors.muted,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool granted;
  final VoidCallback onGrant;

  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (granted)
          Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22)
        else
          TextButton(
            onPressed: onGrant,
            child: Text(
              'Enable',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.monkGold,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final WallpaperMode selected;
  final ValueChanged<WallpaperMode> onSelect;

  const _WallpaperTile({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallpaper Mode',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How the home screen background is drawn.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WallpaperMode.values.map((m) {
            final isSel = m == selected;
            return GestureDetector(
              onTap: () => onSelect(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColors.monk.withAlpha(50)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? AppColors.monkGold
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  m.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSel
                        ? AppColors.monkGold
                        : AppColors.secondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}
