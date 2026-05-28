import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/auth_facade.dart';
import '../../../auth/data/repositories/mock_context_switch_repository.dart';
import '../../../notifications/presentation/widgets/context_switch_toast.dart';

/// Dialog to confirm context switch between teacher and academy owner roles.
///
/// Displays current context and target context, then switches after confirmation.
/// Shows loading indicator during switch operation.
class ContextToggleDialog extends ConsumerStatefulWidget {
  const ContextToggleDialog({super.key});

  @override
  ConsumerState<ContextToggleDialog> createState() =>
      _ContextToggleDialogState();
}

class _ContextToggleDialogState extends ConsumerState<ContextToggleDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.contextToggleDialogTitle,
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.space4),
              _buildContextInfo(authState),
              const SizedBox(height: AppSpacing.space4),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextInfo(AuthState authState) {
    return Column(
      children: [
        // Current context
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.contextToggleCurrentContext,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                _currentContextLabel(authState),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Arrow
        Icon(
          Icons.arrow_downward_rounded,
          color: AppColors.inkSecondary,
          size: 20,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Target context (available alternative)
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.paperAccentSoft),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.contextToggleSwitchTo,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                _targetContextLabel(authState),
                style: AppTypography.headingSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _currentContextLabel(AuthState authState) {
    if (authState is AuthAuthenticated) {
      // For now, assume we're always in teacher context and can switch to owner
      // In production, this would check the actual active context
      return '개인 강사 계정';
    }
    return 'Unknown';
  }

  String _targetContextLabel(AuthState authState) {
    // If we're in teacher context, show owner academy as target
    return '학원장 계정';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(AppStrings.contextToggleCancel),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : () => _handleContextSwitch(context),
            child:
                _isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.paper,
                        ),
                      ),
                    )
                    : Text(AppStrings.contextToggleConfirm),
          ),
        ),
      ],
    );
  }

  Future<void> _handleContextSwitch(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mockContextSwitchRepositoryProvider);
      final result = await repository.switchContext(targetContext: 'owner');

      if (!context.mounted) return;
      Navigator.pop(context);
      _showContextSwitchToast(context, result.activeContext);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계정 전환 실패: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _showContextSwitchToast(BuildContext context, String activeContext) {
    showDialog<void>(
      context: context,
      builder: (_) => ContextSwitchToast(activeContext: activeContext),
    );
  }
}
