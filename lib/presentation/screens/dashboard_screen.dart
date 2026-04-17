import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/brutal_messages.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_stats.dart';
import '../providers/apps_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/daily_score_widget.dart';
import '../widgets/locked_app_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/usage_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final displayStreak = ref.read(statsProvider.notifier).displayStreak;
    final lockedApps = ref.watch(lockedAppsProvider);
    final quote = _getDailyQuote();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Top app bar — minimal, just action icons
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            toolbarHeight: 52,
            titleSpacing: 0,
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded,
                    color: AppColors.primary),
                onPressed: () => context.push('/app-drawer'),
                tooltip: 'All Apps',
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline,
                    color: AppColors.monkGold),
                onPressed: () => context.push('/app-picker'),
                tooltip: 'Manage Locked',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.secondary),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── HERO SECTION ──────────────────────────────────────
                const _HeroSection().animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 28),

                // ── DAILY QUOTE ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.monk.withAlpha(40), width: 1),
                  ),
                  child: Text(
                    '"$quote"',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: AppColors.secondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 20),

                StreakCard(stats: stats, displayStreak: displayStreak)
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 400.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 16),
                DailyScoreWidget(stats: stats)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 16),
                _StatsGrid(stats: stats)
                    .animate()
                    .fadeIn(delay: 340.ms, duration: 400.ms),
                const SizedBox(height: 20),
                const _SectionHeader(
                  title: 'This Week',
                  subtitle: 'Resisted vs Opened',
                ),
                const SizedBox(height: 10),
                WeeklyUsageChart(stats: stats)
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 400.ms),
                const SizedBox(height: 8),
                const _ChartLegend(),
                const SizedBox(height: 20),
                if (lockedApps.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Locked Apps',
                    subtitle:
                        '${lockedApps.where((a) => a.isLocked).length} active',
                    action: TextButton(
                      onPressed: () => context.push('/app-picker'),
                      child: Text(
                        'Manage',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.monkGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lockedApps
                      .where((a) => a.isLocked)
                      .take(5)
                      .map((app) => LockedAppTile(
                            app: app,
                            showStats: true,
                            onTap: () => context.push(
                              '/access-flow/why',
                              extra: {
                                'packageName': app.packageName,
                                'appName': app.appName,
                              },
                            ),
                          )),
                ],
                if (lockedApps.isEmpty) ...[
                  const SizedBox(height: 40),
                  _EmptyState(onTap: () => context.push('/app-picker')),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: lockedApps.isNotEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/app-picker'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.lock_outline),
              label: Text(
                'Lock Apps',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  String _getDailyQuote() {
    const quotes = BrutalMessages.dashboardQuotes;
    final day = DateTime.now().day;
    return quotes[day % quotes.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Image.asset(
          'assets/monk_logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 1.0,
              end: 1.03,
              duration: 2800.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 14),

        // "Monk Mode is On"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 800.ms)
                .then()
                .fadeOut(duration: 800.ms),
            const SizedBox(width: 8),
            Text(
              'Monk Mode is On',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // "You sure wanna continue?"
        Text(
          'You sure wanna continue with your day?',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Divider with label
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'YOUR STATS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REST OF HELPERS (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final UserStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Real weekly aggregates derived from stored daily records.
    int weekOpens = 0;
    int weekResists = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final r = stats.dailyRecords[UserStats.dateKeyFor(day)];
      if (r != null) {
        weekOpens += r.appsOpened;
        weekResists += r.temptationsResisted;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        StatCard(
          label: 'Opens',
          value: '$weekOpens',
          subtitle: 'this week',
          valueColor: AppColors.danger,
          icon: Icons.open_in_new_rounded,
          iconColor: AppColors.danger,
        ),
        StatCard(
          label: 'Resisted',
          value: '$weekResists',
          subtitle: 'this week',
          valueColor: AppColors.success,
          icon: Icons.shield_rounded,
          iconColor: AppColors.success,
        ),
        StatCard(
          label: 'Urges Defeated',
          value: '${stats.totalTemptationsResisted}',
          subtitle: 'all time',
          icon: Icons.flash_on_rounded,
          iconColor: AppColors.monkGold,
        ),
        StatCard(
          label: 'Emergency Passes',
          value: '${stats.emergencyPassesRemaining}/3',
          subtitle: 'remaining',
          valueColor: stats.emergencyPassesRemaining == 0
              ? AppColors.danger
              : AppColors.warning,
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const _SectionHeader({required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendDot(color: AppColors.success, label: 'Resisted'),
        SizedBox(width: 16),
        _LegendDot(color: AppColors.danger, label: 'Opened'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('☯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No apps locked yet.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start guarding your attention.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Pick Apps to Lock'),
          ),
        ],
      ),
    );
  }
}
