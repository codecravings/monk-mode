import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
      ],
      child: const MonkModeApp(),
    ),
  );
}

class MonkModeApp extends ConsumerStatefulWidget {
  const MonkModeApp({super.key});

  @override
  ConsumerState<MonkModeApp> createState() => _MonkModeAppState();
}

class _MonkModeAppState extends ConsumerState<MonkModeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      routerConfig: appRouter,
    );
  }
}
