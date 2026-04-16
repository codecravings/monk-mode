import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/apps_provider.dart';
import '../widgets/locked_app_tile.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final lockedAppsNotifier = ref.watch(lockedAppsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lock Apps'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose which apps to guard.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load apps',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
                ),
              ),
              data: (apps) {
                final filtered = _query.isEmpty
                    ? apps
                    : apps
                        .where((a) =>
                            a.appName.toLowerCase().contains(_query) ||
                            a.packageName.toLowerCase().contains(_query))
                        .toList();

                final locked = filtered
                    .where((a) => lockedAppsNotifier.isLocked(a.packageName))
                    .toList();
                final unlocked = filtered
                    .where((a) => !lockedAppsNotifier.isLocked(a.packageName))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    if (locked.isNotEmpty) ...[
                      _SectionLabel(
                        '🔒 LOCKED  (${locked.length})',
                        AppColors.danger,
                      ),
                      const SizedBox(height: 8),
                      ...locked.map(
                        (app) => LockedAppTile(
                          app: app.copyWith(isLocked: true),
                          onTap: () => lockedAppsNotifier.toggleLock(
                              app.packageName, app.appName),
                        ).animate().fadeIn(duration: 300.ms),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (unlocked.isNotEmpty) ...[
                      _SectionLabel(
                        '📱 AVAILABLE  (${unlocked.length})',
                        AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      ...unlocked.map(
                        (app) => LockedAppTile(
                          app: app,
                          onTap: () => lockedAppsNotifier.toggleLock(
                              app.packageName, app.appName),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      ),
    );
  }
}
