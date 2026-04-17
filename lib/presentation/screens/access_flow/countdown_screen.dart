import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/brutal_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/android_bridge.dart';
import '../../providers/apps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_provider.dart';

class CountdownScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;

  const CountdownScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late int _total;
  bool _canOpen = false;
  late int _msgIndex;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _total = ref.read(settingsProvider).countdownSeconds;
    _remaining = _total;
    _msgIndex = DateTime.now().second %
        BrutalMessages.countdownMessages.length;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining--;
        final msgLen = BrutalMessages.countdownMessages.length;
        _msgIndex = (_msgIndex + 1) % msgLen;
        if (_remaining <= 0) {
          _canOpen = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openApp() async {
    await ref.read(statsProvider.notifier).recordOpened(
          packageName: widget.packageName,
          appName: widget.appName,
        );
    await ref.read(lockedAppsProvider.notifier).recordAttempt(
          widget.packageName,
          opened: true,
        );
    await AndroidBridge.launchApp(widget.packageName);
    if (mounted) context.go('/home');
  }

  void _cancel() {
    ref.read(statsProvider.notifier).recordResisted(
          packageName: widget.packageName,
          appName: widget.appName,
        );
    ref.read(lockedAppsProvider.notifier).recordAttempt(
          widget.packageName,
          opened: false,
        );
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 Last second discipline. Respect.',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / _total;
    final message = BrutalMessages.countdownMessages[_msgIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                '4 / 4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                'Last Chance',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _canOpen
                        ? 1.0
                        : 1.0 + (_pulseController.value * 0.04),
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _canOpen
                                ? AppColors.success
                                : Color.lerp(
                                    AppColors.danger,
                                    AppColors.warning,
                                    1 - progress,
                                  )!,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _canOpen ? '✓' : '$_remaining',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: _canOpen ? 56 : 72,
                              fontWeight: FontWeight.w800,
                              color: _canOpen
                                  ? AppColors.success
                                  : AppColors.primary,
                              height: 1,
                            ),
                          ),
                          if (!_canOpen)
                            Text(
                              'seconds',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  message,
                  key: ValueKey(message),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: AppColors.secondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              if (_canOpen)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _openApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Open App'),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scaleXY(begin: 0.9),
                    const SizedBox(height: 12),
                    _StayStrongButton(onTap: _cancel),
                  ],
                )
              else
                _StayStrongButton(onTap: _cancel),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
