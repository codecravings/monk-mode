import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../providers/apps_provider.dart';
import '../providers/stats_provider.dart';

class EmergencyPassScreen extends ConsumerWidget {
  final String packageName;
  final String appName;

  const EmergencyPassScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final remaining = stats.emergencyPassesRemaining;
    final hasPass = remaining > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.muted, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text('🚨', style: TextStyle(fontSize: 72))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scaleXY(begin: 0.5, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'Emergency Pass',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              Text(
                'Is this truly necessary?',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  color: AppColors.secondary,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: hasPass
                      ? const Color(0xFF1A1200)
                      : AppColors.dangerDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasPass
                        ? AppColors.warning.withAlpha(80)
                        : AppColors.danger.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      hasPass ? '$remaining remaining' : 'No passes left',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: hasPass ? AppColors.warning : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of 3 total · no auto refill',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final used = i >= remaining;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: used
                                ? AppColors.surface
                                : AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: used
                                  ? AppColors.border
                                  : AppColors.warning.withAlpha(120),
                            ),
                          ),
                          child: Icon(
                            used ? Icons.close : Icons.bolt_rounded,
                            color: used ? AppColors.muted : AppColors.warning,
                            size: 20,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              if (!hasPass)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withAlpha(60)),
                  ),
                  child: Text(
                    'You\'ve used all your passes.\nThis is the line you drew. Hold it.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: AppColors.danger,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
              const Spacer(),
              if (hasPass)
                ElevatedButton(
                  onPressed: () => _usePass(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Yes — Use Emergency Pass'),
                ).animate().fadeIn(delay: 300.ms)
              else
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Go Back. Stay Strong.'),
                ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _usePass(BuildContext context, WidgetRef ref) async {
    await ref.read(statsProvider.notifier).recordEmergencyPass(
          packageName: packageName,
          appName: appName,
        );
    await ref.read(lockedAppsProvider.notifier).recordAttempt(
          packageName,
          opened: true,
          usedEmergencyPass: true,
        );
    await AndroidBridge.launchApp(packageName);
    if (context.mounted) context.go('/home');
  }
}
