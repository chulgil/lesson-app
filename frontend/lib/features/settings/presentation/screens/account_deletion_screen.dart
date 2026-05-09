import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Account deletion screen for permanent account deletion.
///
/// Shows warning about data deletion and provides a confirmation dialog
/// before calling the DELETE /api/v1/users/me endpoint.
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.accountDeletionTitle,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space6),
      children: [
        // Warning section
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.profileRed.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.profileRed),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.profileRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    AppStrings.accountDeletionWarningTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.profileRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                AppStrings.accountDeletionWarningIntro,
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.space2),
              _buildWarningItem(AppStrings.accountDeletionWarningPersonalData),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem(AppStrings.accountDeletionWarningLessonData),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem(AppStrings.accountDeletionWarningIrreversible),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem(AppStrings.accountDeletionWarningRetention),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Explanation text
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Text(
            AppStrings.accountDeletionLegalNotice,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space8),

        // Delete button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isDeleting ? null : () => _showConfirmDialog(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.profileRed,
              disabledBackgroundColor: AppColors.profileRed.withValues(
                alpha: 0.5,
              ),
            ),
            child:
                _isDeleting
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.paper,
                        ),
                      ),
                    )
                    : const Text(AppStrings.accountDeletionTitle),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isDeleting ? null : () => context.pop(),
            child: const Text(AppStrings.cancel),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space1),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.profileRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      titleWidget: const Text(AppStrings.accountDeletionConfirmTitle),
      content: const Text(AppStrings.accountDeletionConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            AppStrings.delete,
            style: const TextStyle(color: AppColors.profileRed),
          ),
        ),
      ],
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (!context.mounted) return;

    setState(() => _isDeleting = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Call DELETE /api/v1/users/me
      await apiClient.delete<void>('/api/v1/users/me');

      if (!context.mounted) return;

      // Clear local tokens
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.clearTokens();

      if (!context.mounted) return;

      // Navigate to login screen
      context.go(AppRoutes.login);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.accountDeletionSuccess),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.accountDeletionFailed(e.toString())),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
