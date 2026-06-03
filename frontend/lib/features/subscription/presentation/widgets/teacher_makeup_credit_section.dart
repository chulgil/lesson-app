import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../domain/entities/makeup_credit.dart';
import '../extensions/makeup_credit_visuals.dart';
import '../providers/makeup_credit_providers.dart';

/// Teacher-side per-student makeup credit management (#432 §9.2).
///
/// Lists issued credits and offers manual grant (§4.4) + revoke of unused ones.
class TeacherMakeupCreditSection extends ConsumerWidget {
  final String studentId;
  const TeacherMakeupCreditSection({super.key, required this.studentId});

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
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Text(
            AppStrings.makeupCreditEmpty,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmGrant(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => NotebookAlertDialog(
        title: AppStrings.makeupCreditGrantConfirmTitle,
        content: const Text(AppStrings.makeupCreditGrantConfirmBody),
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
          .grant(studentId: studentId);
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditGrantSuccess)),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupCreditGrantFailed)),
      );
    }
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    MakeupCredit credit,
  ) async {
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
