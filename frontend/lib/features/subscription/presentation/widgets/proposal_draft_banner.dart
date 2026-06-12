import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/repositories/proposal_draft_storage.dart';
import '../providers/proposal_draft_provider.dart';

/// Banner shown at the top of [IssueSubscriptionScreen] when a valid
/// (non-expired) proposal draft exists for the current student.
///
/// Spec: docs/specs/user/phone_verification_policy.md §4.5.
///
/// - "이어서 발급하기" taps restore the draft into the form via [onResume].
/// - The close (X) button shows a discard-confirmation dialog; on confirm,
///   deletes the draft from storage and calls [onDiscard].
class ProposalDraftBanner extends ConsumerWidget {
  const ProposalDraftBanner({
    super.key,
    required this.userId,
    required this.studentId,
    required this.onResume,
    required this.onDiscard,
  });

  final String userId;
  final String studentId;
  final void Function(ProposalDraft draft) onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(proposalDraftProvider(userId, studentId));

    return draftAsync.when(
      data: (draft) {
        if (draft == null) return const SizedBox.shrink();
        return _DraftBannerContent(
          userId: userId,
          studentId: studentId,
          draft: draft,
          onResume: onResume,
          onDiscard: onDiscard,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DraftBannerContent extends ConsumerWidget {
  const _DraftBannerContent({
    required this.userId,
    required this.studentId,
    required this.draft,
    required this.onResume,
    required this.onDiscard,
  });

  final String userId;
  final String studentId;
  final ProposalDraft draft;
  final void Function(ProposalDraft draft) onResume;
  final VoidCallback onDiscard;

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.paper,
            title: Text(
              AppStrings.proposalDraftDiscardTitle,
              style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
            ),
            content: Text(
              AppStrings.proposalDraftDiscardBody,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(AppStrings.proposalDraftDiscardCancel),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(AppStrings.proposalDraftDiscardConfirm),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await ref.read(proposalDraftStorageProvider).delete(userId, studentId);
    ref.invalidate(proposalDraftProvider(userId, studentId));
    onDiscard();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.proposalDraftBannerTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                GestureDetector(
                  onTap: () => onResume(draft),
                  child: Text(
                    AppStrings.proposalDraftBannerResume,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.paperAccent,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _confirmDiscard(context, ref),
          ),
        ],
      ),
    );
  }
}
