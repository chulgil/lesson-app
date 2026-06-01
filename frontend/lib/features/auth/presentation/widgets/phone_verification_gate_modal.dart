import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Phone verification gate modal — shown at E3 (first subscription issuance)
/// when [PhoneVerificationRequiredException] is raised.
///
/// Spec: docs/specs/user/phone_verification_policy.md §4.3 (issue #430).
///
/// Usage:
/// ```dart
/// try {
///   await issueSubscription(...);
/// } on PhoneVerificationRequiredException catch (_) {
///   await PhoneVerificationGate.show(context);
/// }
/// ```
class PhoneVerificationGate {
  PhoneVerificationGate._();

  /// Show the gate modal. Returns ``true`` if the user chose to verify now
  /// (caller may then route to ``AppRoutes.teacherPhoneVerification``).
  /// Returns ``false`` (or ``null``) if the user dismissed it.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _PhoneVerificationGateDialog(),
    );
  }
}

class _PhoneVerificationGateDialog extends StatelessWidget {
  const _PhoneVerificationGateDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.phoneVerificationGateTitle,
              style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.phoneVerificationGateBody,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.phoneVerificationGateRewardLine,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
                context.go(AppRoutes.teacherPhoneVerification);
              },
              child: const Text(AppStrings.phoneVerificationGateCtaVerifyNow),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.phoneVerificationGateCtaLater),
            ),
          ],
        ),
      ),
    );
  }
}
