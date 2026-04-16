import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_stats.dart';
import 'glass_card.dart';

class DailyScoreWidget extends StatelessWidget {
  final UserStats stats;

  const DailyScoreWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final score = stats.todayRecord.score;
    final color = _colorForScore(score);
    final total =
        stats.todayTemptationsResisted + stats.todayAppsOpened;
    final percent =
        total == 0 ? 100 : ((stats.todayTemptationsResisted / total) * 100).round();

    return GlassCard(
      borderColor: color.withAlpha(80),
      child: Row(
        children: [
          Text(score.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S SCORE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                'discipline',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorForScore(DailyScore score) {
    switch (score) {
      case DailyScore.monk:
        return AppColors.success;
      case DailyScore.slipping:
        return AppColors.warning;
      case DailyScore.lost:
        return AppColors.danger;
    }
  }
}
