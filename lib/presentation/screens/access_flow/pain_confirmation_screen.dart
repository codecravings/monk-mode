import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/brutal_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/apps_provider.dart';
import '../../providers/stats_provider.dart';

class PainConfirmationScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;

  const PainConfirmationScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  ConsumerState<PainConfirmationScreen> createState() =>
      _PainConfirmationScreenState();
}

class _PainConfirmationScreenState
    extends ConsumerState<PainConfirmationScreen> {
  late String _message;

  @override
  void initState() {
    super.initState();
    final msgs = BrutalMessages.painConfirmation;
    final idx = DateTime.now().millisecond % msgs.length;
    _message = msgs[idx];
  }

  void _resist() {
    ref.read(statsProvider.notifier).recordResisted();
    ref
        .read(lockedAppsProvider.notifier)
        .recordAttempt(widget.packageName, false);
    context.go('/dashboard');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 The monk wins again.',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _proceed() {
    context.push(
      '/access-flow/countdown',
      extra: {
        'packageName': widget.packageName,
        'appName': widget.appName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: _BackButton(),
              ),
              const Spacer(),
              Text('⚠️', style: const TextStyle(fontSize: 64))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scaleXY(begin: 0.5, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                '3 / 4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.dangerDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.danger.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Remember this moment.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(),
              Column(
                children: [
                  _StayStrongButton(onTap: _resist),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _proceed,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'Open Anyway 😞',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showEmergencyPass(context),
                    child: Text(
                      '🚨 Use Emergency Pass',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyPass(BuildContext context) {
    context.push(
      '/emergency-pass',
      extra: {
        'packageName': widget.packageName,
        'appName': widget.appName,
      },
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
