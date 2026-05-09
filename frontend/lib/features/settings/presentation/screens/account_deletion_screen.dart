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
        title: '계정 삭제',
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
                    '주의',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.profileRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                '계정을 삭제하면 다음과 같은 일이 발생합니다:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              _buildWarningItem('모든 개인 정보 및 데이터가 영구 삭제됩니다'),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem('레슨, 연습 기록, 녹음 파일이 모두 삭제됩니다'),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem('삭제된 계정은 복구할 수 없습니다'),
              const SizedBox(height: AppSpacing.space1),
              _buildWarningItem('데이터는 삭제 신청 후 30일 내에 영구 삭제됩니다'),
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
            '법적 요구사항(GDPR, 개인정보보호법)에 따라, '
            '계정 삭제 신청 후 30일 이내에 모든 데이터가 영구적으로 삭제됩니다. '
            '이 기간 동안 계정에 로그인할 수 없습니다.',
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
              disabledBackgroundColor: AppColors.profileRed.withValues(alpha: 0.5),
            ),
            child: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.paper),
                    ),
                  )
                : const Text('계정 삭제'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isDeleting ? null : () => context.pop(),
            child: const Text('취소'),
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
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      titleWidget: const Text('정말 삭제하시겠습니까?'),
      content: const Text(
        '30일 후 모든 데이터가 영구 삭제됩니다.\n'
        '이 작업은 취소할 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            '삭제',
            style: const TextStyle(color: AppColors.profileRed),
          ),
        ),
      ],
    );

    if (confirmed == true) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (!mounted) return;

    setState(() => _isDeleting = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Call DELETE /api/v1/users/me
      await apiClient.delete<void>('/api/v1/users/me');

      if (!mounted) return;

      // Clear local tokens
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.clearTokens();

      if (!mounted) return;

      // Navigate to login screen
      context.go(AppRoutes.login);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 삭제되었습니다. 30일 후 모든 데이터가 영구 삭제됩니다.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계정 삭제에 실패했습니다: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
