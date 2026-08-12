import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../domain/entities/makeup_credit.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/subscription_selection.dart';
import '../extensions/makeup_credit_visuals.dart';
import '../extensions/subscription_visuals.dart';
import '../providers/makeup_credit_providers.dart';
import '../providers/subscription_providers.dart';
import 'subscription_picker_sheet.dart';

/// Teacher-side per-student makeup credit management (#432 §9.2).
///
/// Lists issued credits and offers manual grant (§4.4) + revoke of unused ones.
class TeacherMakeupCreditSection extends ConsumerWidget {
  final String studentId;

  /// When provided, renders a "전체보기" affordance in the header that
  /// navigates to the full makeup-credit screen (#1165 진입점). Null in the
  /// full screen itself (MakeupCreditScreen) where it would be redundant.
  final VoidCallback? onViewAll;

  const TeacherMakeupCreditSection({
    super.key,
    required this.studentId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(teacherMakeupCreditsProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.makeupCreditManageTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ),
            if (onViewAll != null) ...[
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(
                  Icons.list,
                  size: AppSpacing.iconXS,
                  color: AppColors.ink,
                ),
                // H6 — 텍스트가 affordance 를 지는 이동 액션이므로 밑줄.
                label: Text(
                  AppStrings.viewAll,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.ink,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
            ],
            FilledButton(
              onPressed: () => _confirmGrant(context, ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              ),
              child: const Text(AppStrings.makeupCreditGrantButton),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        creditsAsync.when(
          data: (credits) {
            if (credits.isEmpty) {
              return Text(
                AppStrings.makeupCreditEmpty,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              );
            }
            return Column(
              children: [
                for (final credit in credits)
                  _TeacherCreditRow(
                    credit: credit,
                    onRevoke: () => _confirmRevoke(context, ref, credit),
                  ),
              ],
            );
          },
          loading:
              () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (_, __) => Text(
                AppStrings.makeupCreditEmpty,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
        ),
      ],
    );
  }

  /// Resolves which subscription this manual grant should be attributed to
  /// before confirming (spec §4.4 — source_subscription_id stays nullable).
  ///
  /// Mirrors add_lesson_screen._resolveSubscriptionForStudent's "1개=자동,
  /// 2개+=선택" policy: 0 actives → no attribution (unchanged today), 1 →
  /// auto-attach silently, 2+ → offer the picker (with an explicit "귀속
  /// 없음" choice, since unlike a lesson deduction this grant doesn't require
  /// a subscription).
  Future<void> _confirmGrant(BuildContext context, WidgetRef ref) async {
    String? sourceSubscriptionId;
    String? attributionLabel;
    var showAttributionLine = false;

    try {
      final actives = await ref.read(
        activeStudentSubscriptionsProvider(studentId).future,
      );
      if (!context.mounted) return;

      if (actives.length == 1) {
        sourceSubscriptionId = actives.first.id;
        attributionLabel = actives.first.typeLabel;
        showAttributionLine = true;
      } else if (actives.length >= 2) {
        final picked = await _selectGrantAttribution(context, actives);
        if (!context.mounted) return;
        sourceSubscriptionId = picked?.id;
        attributionLabel = picked?.typeLabel;
        showAttributionLine = true;
      }
    } catch (_) {
      // 수강권 조회 실패는 무귀속으로 폴백 — 지급 자체는 막지 않는다
      // (오늘까지의 동작과 동일).
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: AppStrings.makeupCreditGrantConfirmTitle,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.makeupCreditGrantConfirmBody),
                if (showAttributionLine) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    AppStrings.makeupCreditGrantAttributionLine(
                      attributionLabel ??
                          AppStrings.makeupCreditGrantNoAttributionOption,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
            confirmLabel: AppStrings.makeupCreditGrantButton,
            cancelLabel: AppStrings.cancel,
            onConfirm: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(makeupCreditActionsProvider)
          .grant(
            studentId: studentId,
            sourceSubscriptionId: sourceSubscriptionId,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditGrantSuccess)),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditGrantFailed)),
      );
    }
  }

  /// Bottom-sheet picker offered when the student has 2+ active
  /// subscriptions. Returns the chosen [Subscription], or null when the
  /// teacher picks "귀속 없음" or dismisses the sheet without choosing.
  Future<Subscription?> _selectGrantAttribution(
    BuildContext context,
    List<Subscription> subscriptions,
  ) {
    final sorted = sortSubscriptionsForPicker(subscriptions);
    return showNotebookBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.manualLessonPickerTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.makeupCreditGrantAttributionSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              _NoAttributionOption(onTap: () => Navigator.of(ctx).pop()),
              const SizedBox(height: AppSpacing.space3),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (_, index) {
                    final sub = sorted[index];
                    return SubscriptionPickerCard(
                      subscription: sub,
                      onTap: () => Navigator.of(ctx).pop(sub),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    MakeupCredit credit,
  ) async {
    // R4 — destructive HARD-GATE: revoking must confirm first (grant does).
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: AppStrings.makeupCreditRevokeConfirmTitle,
            content: const Text(AppStrings.makeupCreditRevokeConfirmBody),
            confirmLabel: AppStrings.makeupCreditRevokeButton,
            cancelLabel: AppStrings.cancel,
            onConfirm: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(makeupCreditActionsProvider)
          .revoke(creditId: credit.id, studentId: studentId);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditRevokeSuccess)),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditRevokeFailed)),
      );
    }
  }
}

/// "귀속 없음" tile in the grant attribution picker — mirrors
/// [SubscriptionPickerCard]'s visual language so it reads as one option
/// among the subscription cards, not a separate affordance.
class _NoAttributionOption extends StatelessWidget {
  const _NoAttributionOption({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Text(
          AppStrings.makeupCreditGrantNoAttributionOption,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _TeacherCreditRow extends StatelessWidget {
  final MakeupCredit credit;
  final VoidCallback onRevoke;
  const _TeacherCreditRow({required this.credit, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isUsed = credit.isUsed;
    final isExpired = credit.isExpired(now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.makeupCreditAccruedLine(
                    formatDateMD(credit.createdAt),
                    credit.reason.label,
                  ),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
                if (isUsed)
                  _StatusBadge(label: AppStrings.makeupCreditUsedBadge)
                else if (isExpired)
                  _StatusBadge(label: AppStrings.makeupCreditExpiredBadge),
              ],
            ),
          ),
          // Only unused credits can be revoked.
          if (!isUsed)
            OutlinedButton(
              onPressed: onRevoke,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                foregroundColor: AppColors.paperAccent,
                side: const BorderSide(color: AppColors.paperAccent),
              ),
              child: const Text(AppStrings.makeupCreditRevokeButton),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}
