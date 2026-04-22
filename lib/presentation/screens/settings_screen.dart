import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/datasources/wallpaper_service.dart';
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
                  customPath: settings.customWallpaperPath,
                  dimOpacity: settings.wallpaperDimOpacity,
                  onSelect: (m) {
                    // Sync fire-and-forget — no awaits in the tap handler.
                    settingsNotifier.setWallpaperMode(m);
                  },
                  onPickCustom: () async {
                    final path = await WallpaperService.pickFromGallery();
                    if (path == null) return;
                    await settingsNotifier.setCustomWallpaperPath(path);
                    await settingsNotifier
                        .setWallpaperMode(WallpaperMode.custom);
                  },
                  onClearCustom: () async {
                    await WallpaperService.clear();
                    await settingsNotifier.setCustomWallpaperPath(null);
                  },
                  onDimChanged: settingsNotifier.setWallpaperDimOpacity,
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Show Clock & Date',
                  subtitle: 'Display the big clock block on the home screen',
                  value: settings.showClockOnHome,
                  onChanged: settingsNotifier.setShowClockOnHome,
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Show Streak on Home',
                  subtitle: 'Display the monk streak pill under the clock',
                  value: settings.showStreakOnHome,
                  onChanged: settingsNotifier.setShowStreakOnHome,
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: "Show Today's Intention",
                  subtitle:
                      'One-line focus set each morning, editable from home',
                  value: settings.showIntentionOnHome,
                  onChanged: settingsNotifier.setShowIntentionOnHome,
                ),
                if (settings.showIntentionOnHome) ...[
                  const SizedBox(height: 12),
                  _IntentionEditor(
                    value: settings.intention,
                    onChanged: settingsNotifier.setIntention,
                  ),
                ],
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Show Screen-Time Budget',
                  subtitle: 'Home shows today usage vs your daily limit',
                  value: settings.showScreenTimeOnHome,
                  onChanged: settingsNotifier.setShowScreenTimeOnHome,
                ),
                if (settings.showScreenTimeOnHome) ...[
                  const SizedBox(height: 8),
                  _SliderTile(
                    label: 'Daily Budget',
                    value: settings.screenTimeBudgetMinutes.toDouble(),
                    min: 15,
                    max: 720,
                    divisions: 47,
                    formatValue: _formatBudget,
                    onChanged: (v) => settingsNotifier
                        .setScreenTimeBudgetMinutes(v.round()),
                  ),
                ],
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

  static String _formatBudget(double minutes) {
    final total = minutes.round();
    if (total < 60) return '${total}m';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
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
  final String Function(double)? formatValue;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unit,
    this.labels,
    this.formatValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayVal = formatValue != null
        ? formatValue!(value)
        : labels != null
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
  final String? customPath;
  final double dimOpacity;
  final ValueChanged<WallpaperMode> onSelect;
  final VoidCallback onPickCustom;
  final VoidCallback onClearCustom;
  final ValueChanged<double> onDimChanged;

  const _WallpaperTile({
    required this.selected,
    required this.customPath,
    required this.dimOpacity,
    required this.onSelect,
    required this.onPickCustom,
    required this.onClearCustom,
    required this.onDimChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallpaper',
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
        if (selected == WallpaperMode.custom) ...[
          const SizedBox(height: 14),
          _CustomWallpaperBlock(
            path: customPath,
            onPick: onPickCustom,
            onClear: onClearCustom,
          ),
        ],
        const SizedBox(height: 18),
        _DimSlider(value: dimOpacity, onChanged: onDimChanged),
      ],
    );
  }
}

class _CustomWallpaperBlock extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _CustomWallpaperBlock({
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && File(path!).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tap the preview itself to replace — always obvious.
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: 72,
                height: 108,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasImage
                        ? AppColors.monkGold.withAlpha(120)
                        : AppColors.border,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(File(path!), fit: BoxFit.cover)
                    else
                      const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.muted, size: 28),
                      ),
                    if (hasImage)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          alignment: Alignment.center,
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage ? 'Custom image set' : 'No image picked',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          hasImage ? AppColors.monkGold : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasImage
                        ? 'Tap preview or Change to pick a new one.'
                        : 'Pick an image from your gallery.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPick,
                icon: Icon(
                  hasImage
                      ? Icons.swap_horiz_rounded
                      : Icons.photo_library_outlined,
                  size: 18,
                ),
                label: Text(hasImage ? 'Change wallpaper' : 'Pick wallpaper'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withAlpha(120)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DimSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _DimSlider({required this.value, required this.onChanged});

  @override
  State<_DimSlider> createState() => _DimSliderState();
}

class _DimSliderState extends State<_DimSlider> {
  // When null, the slider mirrors widget.value from the parent. While the
  // user is actively dragging, this holds the in-flight drag value so the UI
  // can animate smoothly without flushing to SharedPreferences every tick.
  double? _dragValue;

  double get _effective => _dragValue ?? widget.value;

  @override
  Widget build(BuildContext context) {
    final pct = (_effective * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dim Overlay',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.monkGold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.monkGold,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.monkGold,
            overlayColor: AppColors.monkGold.withAlpha(50),
          ),
          child: Slider(
            value: _effective.clamp(0.0, 0.85),
            min: 0,
            max: 0.85,
            divisions: 17,
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              widget.onChanged(v);
              setState(() => _dragValue = null);
            },
          ),
        ),
        Text(
          'Darken the wallpaper for more focus.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _IntentionEditor extends StatefulWidget {
  final String value;
  final Future<void> Function(String) onChanged;

  const _IntentionEditor({required this.value, required this.onChanged});

  @override
  State<_IntentionEditor> createState() => _IntentionEditorState();
}

class _IntentionEditorState extends State<_IntentionEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _IntentionEditor old) {
    super.didUpdateWidget(old);
    // Only overwrite the buffer if the stored value changed and the user is
    // not currently editing — otherwise we'd clobber in-flight typing.
    if (!_focus.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    // Persist on blur — matches the "set it and move on" mental model.
    if (!_focus.hasFocus && _controller.text != widget.value) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      maxLength: 80,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: (v) => widget.onChanged(v),
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.primary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Ship the draft. Hit the gym. Read 20 pages.',
        hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.muted),
        counterStyle: GoogleFonts.spaceGrotesk(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.monkGold),
        ),
      ),
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
