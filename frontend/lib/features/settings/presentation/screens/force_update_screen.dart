import 'dart:io';

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

  /// Android application id, used to deep-link to the Play Store listing.
  static const String _androidPackage = 'app.lessonaza';

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
    // Route to the platform's own store; Android must go to the Play Store,
    // not the App Store. (#5 D-G3)
    final targets = storeTargets(isAndroid: Platform.isAndroid);

    for (final target in targets) {
      if (await _tryLaunch(target)) return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.forceUpdateStoreUnavailable)),
      );
    }
  }

  /// Ordered list of store deep links to try for the running platform.
  ///
  /// Android: prefer the `market://` scheme (opens the Play app directly),
  /// falling back to the https listing for devices without the Play app.
  /// Apple: direct product page when the id is configured, otherwise a store
  /// search so the button is never a NO-OP.
  @visibleForTesting
  static List<Uri> storeTargets({required bool isAndroid}) {
    if (isAndroid) {
      return [
        Uri.parse('market://details?id=$_androidPackage'),
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$_androidPackage',
        ),
      ];
    }
    return [
      if (_appStoreId.isNotEmpty)
        Uri.parse('https://apps.apple.com/app/$_appName/id$_appStoreId')
      else
        Uri.parse('https://apps.apple.com/search?term=$_appName'),
    ];
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
