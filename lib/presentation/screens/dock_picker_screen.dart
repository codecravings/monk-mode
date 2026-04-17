import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_info.dart';
import '../providers/apps_provider.dart';
import '../providers/settings_provider.dart';

class DockPickerScreen extends ConsumerStatefulWidget {
  const DockPickerScreen({super.key});

  @override
  ConsumerState<DockPickerScreen> createState() => _DockPickerScreenState();
}

class _DockPickerScreenState extends ConsumerState<DockPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final pinned = settings.pinnedDockApps;
    final visibleAsync = ref.watch(visibleAppsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Dock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
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
                  'Pick up to 3 apps for your home dock. Tap a pinned app to unpin. When the dock is full, tap any new app to replace one.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _PinnedPreview(
                  pinned: pinned,
                  onRemove: (pkg) => ref
                      .read(settingsProvider.notifier)
                      .unpinDockApp(pkg),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase().trim()),
                  style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: 'Search apps',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.muted),
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
          const SizedBox(height: 12),
          Expanded(
            child: visibleAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Failed to load apps',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
                ),
              ),
              data: (apps) {
                final filtered = _query.isEmpty
                    ? apps
                    : apps
                        .where((a) => a.appName
                            .toLowerCase()
                            .contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty
                          ? 'No visible apps.'
                          : 'No apps match "$_query".',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.muted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final app = filtered[i];
                    final isPinned = pinned.contains(app.packageName);
                    return _DockAppRow(
                      letter: app.appName.isNotEmpty
                          ? app.appName[0].toUpperCase()
                          : '?',
                      name: app.appName,
                      pinned: isPinned,
                      onTap: () => _handleTap(app, apps, pinned),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(
    AppInfo app,
    List<AppInfo> allApps,
    List<String> pinned,
  ) async {
    final notifier = ref.read(settingsProvider.notifier);
    final isPinned = pinned.contains(app.packageName);
    if (isPinned) {
      await notifier.unpinDockApp(app.packageName);
      return;
    }
    if (pinned.length < 3) {
      await notifier.toggleDockApp(app.packageName);
      return;
    }
    // Full dock: ask which pinned app to swap out.
    final byPkg = {for (final a in allApps) a.packageName: a};
    final replaceTarget = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReplaceSheet(
        incoming: app,
        pinned: pinned
            .map((p) => byPkg[p])
            .whereType<AppInfo>()
            .toList(),
      ),
    );
    if (replaceTarget == null || !mounted) return;
    await notifier.replaceDockApp(
      oldPackage: replaceTarget,
      newPackage: app.packageName,
    );
    if (!mounted) return;
    final replacedName = byPkg[replaceTarget]?.appName ?? 'app';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${app.appName} replaced $replacedName',
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PinnedPreview extends StatelessWidget {
  final List<String> pinned;
  final ValueChanged<String> onRemove;

  const _PinnedPreview({required this.pinned, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${pinned.length}/3 pinned',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: pinned.length >= 3 ? AppColors.warning : AppColors.monkGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pinned
                  .map((pkg) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          label: Text(
                            _shortName(pkg),
                            style: GoogleFonts.spaceGrotesk(fontSize: 12),
                          ),
                          onDeleted: () => onRemove(pkg),
                          deleteIconColor: AppColors.muted,
                          backgroundColor: AppColors.surfaceElevated,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _shortName(String pkg) {
    final parts = pkg.split('.');
    return parts.isNotEmpty ? parts.last : pkg;
  }
}

class _DockAppRow extends StatelessWidget {
  final String letter;
  final String name;
  final bool pinned;
  final VoidCallback onTap;

  const _DockAppRow({
    required this.letter,
    required this.name,
    required this.pinned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pinned
                ? AppColors.monkGold.withAlpha(120)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                letter,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: pinned ? AppColors.monkGold : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplaceSheet extends StatelessWidget {
  final AppInfo incoming;
  final List<AppInfo> pinned;

  const _ReplaceSheet({required this.incoming, required this.pinned});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dock is full',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Which app should ${incoming.appName} replace?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            ...pinned.map(
              (app) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    app.appName.isNotEmpty
                        ? app.appName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                title: Text(
                  app.appName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                trailing: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.muted,
                ),
                onTap: () => Navigator.pop(context, app.packageName),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
