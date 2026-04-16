import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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
    final statsNotifier = ref.read(statsProvider.notifier);
    final lastSession = statsNotifier.getLastSessionMinutes(packageName);
    final weeklyOpens = statsNotifier.getWeeklyOpenCount(packageName);
    final weeklyHours = statsNotifier.getWeeklyHours(packageName);

    final facts = _buildFacts(appName, lastSession, weeklyOpens, weeklyHours);

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
                'Here\'s what this app costs you.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: AppColors.secondary,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: facts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _RegretFact(
                    fact: facts[i],
                    index: i,
                  ),
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

  List<_RegretData> _buildFacts(
      String appName, int lastMins, int weeklyOpens, int weeklyHours) {
    return [
      _RegretData(
        icon: '⏱️',
        stat: '$lastMins min',
        label: 'avg session',
        description: 'Last time you said "just 5 minutes."',
        color: AppColors.danger,
      ),
      _RegretData(
        icon: '📅',
        stat: '$weeklyOpens×',
        label: 'this week',
        description: 'You unlocked $appName $weeklyOpens times in 7 days.',
        color: AppColors.warning,
      ),
      _RegretData(
        icon: '🕳️',
        stat: '${weeklyHours}h',
        label: 'stolen this week',
        description:
            '$appName took ${weeklyHours}h from your life this week.',
        color: AppColors.danger,
      ),
      _RegretData(
        icon: '🎯',
        stat: '0',
        label: 'goals it serves',
        description: 'You said you would focus today.',
        color: AppColors.muted,
      ),
    ];
  }

  void _resist(BuildContext context, WidgetRef ref) {
    ref.read(statsProvider.notifier).recordResisted();
    ref
        .read(lockedAppsProvider.notifier)
        .recordAttempt(packageName, false);
    context.go('/dashboard');
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
        border: Border.all(
          color: fact.color.withAlpha(60),
          width: 1,
        ),
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
          border: Border.all(
            color: AppColors.success.withAlpha(100),
            width: 1,
          ),
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
            style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

