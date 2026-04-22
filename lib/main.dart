import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_storage.dart';
import 'presentation/providers/apps_provider.dart';
import 'presentation/providers/permissions_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/storage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080808),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = await LocalStorage.create();
  // Decide before the first frame whether to show the splash at all — cuts
  // the cold-start path to one screen for onboarded users (home paints
  // immediately after Flutter's first frame, with no splash delay).
  final skipSplash = storage.isOnboardingDone();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
      ],
      child: MonkModeApp(skipSplash: skipSplash),
    ),
  );
}

class MonkModeApp extends ConsumerStatefulWidget {
  final bool skipSplash;

  const MonkModeApp({super.key, required this.skipSplash});

  @override
  ConsumerState<MonkModeApp> createState() => _MonkModeAppState();
}

class _MonkModeAppState extends ConsumerState<MonkModeApp>
    with WidgetsBindingObserver {
  Timer? _rolloverTimer;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter(skipSplash: widget.skipSplash);
    _scheduleRolloverTick();
  }

  @override
  void dispose() {
    _rolloverTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Defer to the next frame so the first paint after resume is not
      // blocked by provider refreshes — fixes the "stuck on splash" look
      // some users hit when bringing the app back from recents.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(permissionsProvider.notifier).refresh();
        ref.read(statsProvider.notifier).rolloverIfNeeded();
        ref.invalidate(installedAppsProvider);
        ref.invalidate(todayScreenTimeProvider);
      });
      _scheduleRolloverTick();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _rolloverTimer?.cancel();
      _rolloverTimer = null;
    }
  }

  /// Fire on the next minute-top then every 60s so the streak rolls across
  /// midnight even if the app is left open — without relying on resume.
  void _scheduleRolloverTick() {
    _rolloverTimer?.cancel();
    final now = DateTime.now();
    final msToNextMinute =
        (60 - now.second) * 1000 - now.millisecond;
    _rolloverTimer = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) return;
      ref.read(statsProvider.notifier).rolloverIfNeeded();
      _rolloverTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!mounted) return;
        ref.read(statsProvider.notifier).rolloverIfNeeded();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Monk Mode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
