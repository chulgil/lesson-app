import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/auth_facade.dart';
import '../../../notifications/notifications_facade.dart';

/// Backend wire value for the academy-owner context.
const _ownerContext = 'academy_owner';

/// Dialog to confirm context switch between teacher and academy owner roles.
///
/// Loads the real available contexts (GET /auth/context), shows the current →
/// target labels, then calls POST /auth/context/switch on confirm. The new
/// access token is persisted and context-derived state is invalidated.
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
    final contextInfo = ref.watch(currentContextProvider);

    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
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
              contextInfo.when(
                data: (info) {
                  final target = _resolveTarget(info);
                  if (target == null) {
                    return Text(
                      AppStrings.contextToggleSwitchFailed,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContextInfo(info, target),
                      const SizedBox(height: AppSpacing.space4),
                      _buildActionButtons(context, info, target),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Text(
                  AppStrings.contextToggleSwitchFailed,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The context the user would switch into: the available context whose wire
  /// value differs from the active one. Falls back to the first available
  /// context when no context is active yet. Null when nothing to toggle.
  AvailableContext? _resolveTarget(ContextInfo info) {
    if (info.availableContexts.isEmpty) return null;
    for (final candidate in info.availableContexts) {
      if (candidate.context != info.activeContext) return candidate;
    }
    return info.availableContexts.first;
  }

  Widget _buildContextInfo(ContextInfo info, AvailableContext target) {
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
                _currentContextLabel(info, target),
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
              Text(target.label, style: AppTypography.headingSmall),
            ],
          ),
        ),
      ],
    );
  }

  String _currentContextLabel(ContextInfo info, AvailableContext target) {
    // Prefer the labelled current context from the available list.
    for (final candidate in info.availableContexts) {
      if (candidate.context == info.activeContext) return candidate.label;
    }
    // No active context selected — name it by the opposite of the target.
    return target.context == _ownerContext
        ? AppStrings.contextToggleTeacherContext
        : AppStrings.contextToggleOwnerContext;
  }

  Widget _buildActionButtons(
    BuildContext context,
    ContextInfo info,
    AvailableContext target,
  ) {
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
            onPressed: _isLoading
                ? null
                : () => _handleContextSwitch(context, target),
            child: _isLoading
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

  Future<void> _handleContextSwitch(
    BuildContext context,
    AvailableContext target,
  ) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(contextSwitchRepositoryProvider);
      final result = await repository.switchContext(
        targetContext: target.context,
        academyId: target.academyId,
      );

      await _persistAccessToken(result.tokens.accessToken);
      // Refresh the context list so the toggle reflects the new active context.
      ref.invalidate(currentContextProvider);

      if (!context.mounted) return;
      Navigator.pop(context);
      _showContextSwitchToast(context, result.activeContext);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.contextToggleSwitchFailed)),
      );
      setState(() => _isLoading = false);
    }
  }

  /// Persist the freshly issued access token, keeping the existing refresh
  /// token (the switch endpoint only rotates the access token).
  Future<void> _persistAccessToken(String accessToken) async {
    if (accessToken.isEmpty) return;
    final tokenStorage = ref.read(tokenStorageProvider);
    final refreshToken = await tokenStorage.getRefreshToken() ?? '';
    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  void _showContextSwitchToast(BuildContext context, String activeContext) {
    showDialog<void>(
      context: context,
      builder: (_) => ContextSwitchToast(activeContext: activeContext),
    );
  }
}
