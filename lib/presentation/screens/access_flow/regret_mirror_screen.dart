import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/android_bridge.dart';
import '../../providers/apps_provider.dart';
import '../../providers/stats_provider.dart';

class RegretMirrorScreen extends ConsumerWidget {
  final String packageName;
  final String appName;

  const RegretMirrorScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(appUsageProvider(packageName));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _BackButton(),
              const SizedBox(height: 40),
              Text(
                '2 / 4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                'The Regret\nMirror',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.15,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                "Here's what $appName costs you.",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: AppColors.secondary,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),
              Expanded(
                child: usageAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (_, __) => _UsagePermissionCta(
                    onGrant: () async {
                      await AndroidBridge.openUsageStatsSettings();
                    },
                  ),
                  data: (usage) {
                    if (!usage.granted) {
                      return _UsagePermissionCta(
                        onGrant: () async {
                          await AndroidBridge.openUsageStatsSettings();
                        },
                      );
                    }
                    final facts = _buildFacts(usage);
                    if (facts.isEmpty) {
                      return _EmptyUsage(appName: appName);
                    }
                    return ListView.separated(
                      itemCount: facts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _RegretFact(fact: facts[i], index: i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push(
                  '/access-flow/pain',
                  extra: {
                    'packageName': packageName,
                    'appName': appName,
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('I understand. Continue.'),
              ),
              const SizedBox(height: 12),
              _StayStrongButton(onTap: () => _resist(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  List<_RegretData> _buildFacts(AppUsageStats usage) {
    final facts = <_RegretData>[];
    if (usage.lastSessionMinutes > 0) {
      facts.add(_RegretData(
        icon: '⏱️',
        stat: '${usage.lastSessionMinutes} min',
        label: 'last session',
        description: 'You said "just a minute" last time too.',
        color: AppColors.danger,
      ));
    }
    if (usage.openCount > 0) {
      facts.add(_RegretData(
        icon: '📅',
        stat: '${usage.openCount}×',
        label: 'this week',
        description:
            'You opened $appName ${usage.openCount} times in the last 7 days.',
        color: AppColors.warning,
      ));
    }
    if (usage.totalMinutes > 0) {
      final hours = usage.totalMinutes ~/ 60;
      final mins = usage.totalMinutes % 60;
      final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
      facts.add(_RegretData(
        icon: '🕳️',
        stat: timeStr,
        label: 'stolen this week',
        description:
            '$appName took $timeStr from your life in 7 days.',
        color: AppColors.danger,
      ));
    }
    if (usage.avgSessionMinutes > 0) {
      facts.add(_RegretData(
        icon: '📈',
        stat: '${usage.avgSessionMinutes} min',
        label: 'avg session',
        description: 'Every open averages this long. Not "just a quick check."',
        color: AppColors.warning,
      ));
    }
    return facts;
  }

  void _resist(BuildContext context, WidgetRef ref) {
    ref
        .read(statsProvider.notifier)
        .recordResisted(packageName: packageName, appName: appName);
    ref.read(lockedAppsProvider.notifier).recordAttempt(
          packageName,
          opened: false,
        );
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 Urge defeated. Streak intact.',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _RegretData {
  final String icon;
  final String stat;
  final String label;
  final String description;
  final Color color;

  const _RegretData({
    required this.icon,
    required this.stat,
    required this.label,
    required this.description,
    required this.color,
  });
}

class _RegretFact extends StatelessWidget {
  final _RegretData fact;
  final int index;

  const _RegretFact({required this.fact, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fact.color.withAlpha(60), width: 1),
      ),
      child: Row(
        children: [
          Text(fact.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fact.stat,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: fact.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fact.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  fact.description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 150 + index * 120),
          duration: 400.ms,
        )
        .slideX(begin: 0.15, end: 0);
  }
}

class _UsagePermissionCta extends StatelessWidget {
  final VoidCallback onGrant;

  const _UsagePermissionCta({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔒', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Usage Access needed',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Grant usage access so the Regret Mirror can show real data instead of nothing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGrant,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.monkGold,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Enable Usage Access'),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsage extends StatelessWidget {
  final String appName;

  const _EmptyUsage({required this.appName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No recent usage of $appName.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clean slate. Keep it that way.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StayStrongButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StayStrongButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003018), Color(0xFF001A0E)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withAlpha(100), width: 1),
        ),
        child: Center(
          child: Text(
            'Stay Strong 🔥',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.muted, size: 16),
          const SizedBox(width: 6),
          Text(
            'Back',
            style:
                GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
