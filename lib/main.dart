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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter(skipSplash: widget.skipSplash);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-read permissions from the OS and advance any crossed midnights.
      ref.read(permissionsProvider.notifier).refresh();
      ref.read(statsProvider.notifier).rolloverIfNeeded();
      ref.invalidate(installedAppsProvider);
    }
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
