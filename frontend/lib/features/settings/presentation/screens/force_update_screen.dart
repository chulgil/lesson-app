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

  /// Apple App Store numeric id for the app, injected at build time.
  ///
  /// FLAG: the real id is not yet known; the default is a placeholder.
  /// Provide it via `--dart-define=APP_STORE_ID=<id>` when building for
  /// release so the direct App Store link works. Until then, [_openStore]
  /// falls back to an App Store search.
  static const String _appStoreId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: '',
  );

  static const String _appName = 'lessonaza';

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
                  onPressed: () => _openStore(context),
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

  Future<void> _openStore(BuildContext context) async {
    // Direct product page when the App Store id is configured, otherwise a
    // store search so the button is never a NO-OP. (#5 D-G3)
    final target =
        _appStoreId.isNotEmpty
            ? Uri.parse('https://apps.apple.com/app/$_appName/id$_appStoreId')
            : Uri.parse('https://apps.apple.com/search?term=$_appName');

    final launched = await _tryLaunch(target);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.forceUpdateStoreUnavailable)),
      );
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
