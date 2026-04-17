import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../providers/permissions_provider.dart';
import '../providers/storage_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      emoji: '☯',
      title: 'Welcome to\nMonk Mode',
      subtitle:
          'A ruthless guardian for your attention.\nNot a productivity app.\nA discipline system.',
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: 'Lock Your\nDistractions',
      subtitle:
          'Hidden apps vanish from your launcher.\nThe only way in is through The Gauntlet.',
    ),
    _OnboardingPage(
      emoji: '🔥',
      title: 'Build Your\nStreak',
      subtitle:
          'Every resistance compounds.\nEvery open resets the clock.\nThe monk earns his peace.',
    ),
    _OnboardingPage(
      emoji: '⚙️',
      title: 'Enable\nPermissions',
      subtitle: 'Four permissions power the system.',
      isPermissions: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsProvider.notifier).refresh();
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(storageProvider).setOnboardingDone();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Text(page.emoji,
                                  style: const TextStyle(fontSize: 80))
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scaleXY(begin: 0.7),
                          const SizedBox(height: 32),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.15,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 16),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              color: AppColors.secondary,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          if (page.isPermissions) ...[
                            const SizedBox(height: 32),
                            _PermissionTile(
                              title: 'Default Launcher',
                              subtitle: 'Replace your home screen',
                              granted: perms.defaultLauncher,
                              onGrant: () async {
                                await AndroidBridge.requestDefaultLauncher();
                                await Future.delayed(
                                    const Duration(milliseconds: 600));
                                ref
                                    .read(permissionsProvider.notifier)
                                    .refresh();
                              },
                            ),
                            const SizedBox(height: 10),
                            _PermissionTile(
                              title: 'Accessibility Service',
                              subtitle: 'Intercepts locked app opens',
                              granted: perms.accessibility,
                              onGrant: () async {
                                await AndroidBridge
                                    .openAccessibilitySettings();
                              },
                            ),
                            const SizedBox(height: 10),
                            _PermissionTile(
                              title: 'Usage Stats',
                              subtitle: 'Real data for Regret Mirror',
                              granted: perms.usageStats,
                              onGrant: () async {
                                await AndroidBridge
                                    .openUsageStatsSettings();
                              },
                            ),
                            const SizedBox(height: 10),
                            _PermissionTile(
                              title: 'Battery Optimization',
                              subtitle: 'Keep lock engine alive in background',
                              granted: perms.batteryOptimizationIgnored,
                              onGrant: () async {
                                await AndroidBridge
                                    .openBatteryOptimizationSettings();
                                await Future.delayed(
                                    const Duration(milliseconds: 600));
                                ref
                                    .read(permissionsProvider.notifier)
                                    .refresh();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == _currentPage ? 24 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppColors.primary
                              : AppColors.muted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(
                      _currentPage < _pages.length - 1
                          ? 'Continue'
                          : 'Enter Monk Mode',
                    ),
                  ),
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip permissions for now',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isPermissions;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.isPermissions = false,
  });
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onGrant;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              granted ? AppColors.success.withAlpha(80) : AppColors.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? AppColors.success : AppColors.muted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
          if (!granted)
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
      ),
    );
  }
}
