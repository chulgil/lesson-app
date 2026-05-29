import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Full-screen blocker shown when app version < server min_version.
///
/// Prevents access to the app until the user updates via the store.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.minVersion,
  });

  final String currentVersion;
  final String minVersion;

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const NotebookGlyph(NotebookGlyph.arrowUp, size: 48),
              const SizedBox(height: AppSpacing.space6),
              Text(
                AppStrings.forceUpdateTitle,
                style: AppTypography.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                AppStrings.forceUpdateBody(minVersion),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.forceUpdateCurrentVersion(currentVersion),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _openStore,
                  child: Text(AppStrings.forceUpdateAction),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    // iOS App Store URL — update with actual app ID when available
    final uri = Uri.parse('https://apps.apple.com/app/lessonaza/id0000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
