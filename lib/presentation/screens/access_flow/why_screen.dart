import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/usage_record.dart';
import '../../providers/access_flow_provider.dart';

class WhyScreen extends ConsumerWidget {
  final String packageName;
  final String appName;

  const WhyScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(accessFlowProvider.notifier);
    notifier.startFlow(packageName, appName);

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
                '1 / 4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                'Why are you\nopening this?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.15,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                appName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: AccessReason.values.map((reason) {
                    return _ReasonOption(
                      reason: reason,
                      onTap: () {
                        notifier.setReason(reason);
                        context.push(
                          '/access-flow/regret',
                          extra: {
                            'packageName': packageName,
                            'appName': appName,
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  final AccessReason reason;
  final VoidCallback onTap;

  const _ReasonOption({required this.reason, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Text(reason.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              reason.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.muted, size: 22),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + reason.index * 80),
          duration: 300.ms,
        )
        .slideX(begin: 0.1, end: 0);
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
            'Back to safety',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
