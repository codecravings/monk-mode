import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_info.dart';

class LockedAppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback? onTap;
  final bool showStats;

  const LockedAppTile({
    super.key,
    required this.app,
    this.onTap,
    this.showStats = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: app.isLocked
                ? AppColors.danger.withAlpha(60)
                : AppColors.border,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (showStats && app.isLocked)
                    Text(
                      '${app.totalAttempts} attempts · ${app.totalResisted} resisted',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (app.isLocked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dangerDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  'LOCKED',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              Icon(Icons.add_circle_outline,
                  color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}
