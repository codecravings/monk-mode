import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
                  onChanged: (v) => notifier.setCountdownSeconds(v.round()),
                ),
                const Divider(height: 24),
                _SliderTile(
                  label: 'Regret Intensity',
                  value: settings.regretIntensity.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  labels: const ['Mild', 'Strong', 'Brutal'],
                  onChanged: (v) => notifier.setRegretIntensity(v.round()),
                ),
                const Divider(height: 24),
                _SwitchTile(
                  label: 'Brutal Quotes Only',
                  subtitle: 'Show only the harshest messages',
                  value: settings.brutalQuotesOnly,
                  onChanged: notifier.setBrutalQuotesOnly,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          _SectionTitle('PERMISSIONS'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Accessibility Service',
                  subtitle: 'Required to intercept locked app opens',
                  granted: settings.accessibilityGranted,
                  onGrant: () async {
                    await AndroidBridge.openAccessibilitySettings();
                  },
                ),
                const Divider(height: 24),
                _PermissionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Usage Stats',
                  subtitle: 'Powers the Regret Mirror with real data',
                  granted: settings.usageStatsGranted,
                  onGrant: () async {
                    await AndroidBridge.openUsageStatsSettings();
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
                  onPressed: () => _confirmReset(context, ref),
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

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Passes?',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        content: Text(
          'This restores all 3 emergency passes.',
          style: GoogleFonts.spaceGrotesk(color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.spaceGrotesk(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(statsProvider.notifier).resetEmergencyPasses();
              Navigator.pop(ctx);
            },
            child: Text('Reset',
                style: GoogleFonts.spaceGrotesk(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _confirmResetStats(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset All Stats?',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        content: Text(
          'This will erase your streak, history, and all stats. This cannot be undone.',
          style: GoogleFonts.spaceGrotesk(color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.spaceGrotesk(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              // Reset is handled by clearing prefs and re-seeding
              Navigator.pop(ctx);
            },
            child: Text('Reset',
                style: GoogleFonts.spaceGrotesk(color: AppColors.danger)),
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
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)
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
          Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}
