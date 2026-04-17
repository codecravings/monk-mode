import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/android_bridge.dart';
import '../../data/models/app_info.dart';
import '../providers/apps_provider.dart';

class AppDrawerScreen extends ConsumerStatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  ConsumerState<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends ConsumerState<AppDrawerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleAsync = ref.watch(visibleAppsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'All Apps',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_outline,
                        color: AppColors.monkGold),
                    tooltip: 'Lock apps',
                    onPressed: () => context.push('/app-picker'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.toLowerCase().trim()),
                style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: visibleAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
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
                              a.appName.toLowerCase().contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No apps visible.'
                            : 'No apps match "$_query".',
                        style:
                            GoogleFonts.spaceGrotesk(color: AppColors.muted),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final app = filtered[i];
                      return _AppIconTile(
                        app: app,
                        onTap: () => _launch(app),
                        onLongPress: () => _showLockSheet(app),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 10 * i),
                              duration: 200.ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(AppInfo app) async {
    final ok = await AndroidBridge.launchApp(app.packageName);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch ${app.appName}',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  void _showLockSheet(AppInfo app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.appName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                app.packageName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline,
                    color: AppColors.danger),
                title: Text(
                  'Lock & Hide',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                subtitle: Text(
                  'Removes from drawer. Gate required to open.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(lockedAppsProvider.notifier)
                      .toggleLock(app.packageName, app.appName);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔒 ${app.appName} locked.',
                          style: GoogleFonts.spaceGrotesk(),
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIconTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppIconTile({
    required this.app,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceElevated,
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                app.appName.isNotEmpty
                    ? app.appName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              app.appName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
