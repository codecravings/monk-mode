import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_stats.dart';

class StreakCard extends StatelessWidget {
  final UserStats stats;
  final int displayStreak;

  const StreakCard({
    super.key,
    required this.stats,
    required this.displayStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1008), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.monk.withAlpha(80), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Streak number + label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONK STREAK',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.monk,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$displayStreak',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            'days',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _FlameIcon(streak: displayStreak),
            ],
          ),
          const SizedBox(height: 14),
          // Mini stats — use Row with spaceBetween + Expanded to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                label: 'Best',
                value: '${stats.bestStreak}d',
                color: AppColors.monkGold,
              ),
              _MiniStat(
                label: 'Today',
                value: '${stats.todayTemptationsResisted}',
                color: AppColors.success,
              ),
              _MiniStat(
                label: 'Total',
                value: '${stats.totalTemptationsResisted}',
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlameIcon extends StatelessWidget {
  final int streak;
  const _FlameIcon({required this.streak});

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    return Text(
      isActive ? '🔥' : '💀',
      style: const TextStyle(fontSize: 48),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(begin: 1.0, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.06, end: 1.0, duration: 1200.ms, curve: Curves.easeInOut);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
