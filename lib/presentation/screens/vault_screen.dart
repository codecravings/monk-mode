import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/apps_provider.dart';
import '../widgets/locked_app_tile.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedAsync = ref.watch(lockedAppListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vault'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Manage',
            onPressed: () => context.push('/app-picker'),
          ),
        ],
      ),
      body: SafeArea(
        child: lockedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
          error: (_, __) => Center(
            child: Text(
              'Failed to load locked apps',
              style: GoogleFonts.spaceGrotesk(color: AppColors.muted),
            ),
          ),
          data: (apps) {
            if (apps.isEmpty) return const _EmptyVault();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hidden from your drawer. Accessible only through the gate.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: apps.length,
                      itemBuilder: (context, i) {
                        final app = apps[i];
                        return LockedAppTile(
                          app: app,
                          showStats: true,
                          onTap: () => context.push(
                            '/access-flow/why',
                            extra: {
                              'packageName': app.packageName,
                              'appName': app.appName,
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗝️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Vault is empty',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lock an app to hide it from your drawer\nand gate access through Monk Mode.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => context.push('/app-picker'),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Pick Apps to Lock'),
            ),
          ],
        ),
      ),
    );
  }
}
