import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../providers/subscription_proposal_providers.dart';

/// Duplicate proposal guard (#696) — spec subscription_master.md §3.1.5.
///
/// Call before creating a proposal or issuing a subscription. If the student
/// already has a `pending`/`paymentNotified` proposal from this teacher, a
/// warning dialog is shown:
///
/// - [기존 제안 보기] → closes and routes to the existing proposal detail.
/// - [기존 제안 취소 후 재제안] → cancels the existing proposal, then returns
///   `true` so the caller proceeds with the new proposal.
///
/// Returns `true` when creation may proceed (no duplicate, or the existing
/// proposal was cancelled), `false` when the flow must stop.
Future<bool> ensureNoDuplicateProposal({
  required BuildContext context,
  required WidgetRef ref,
  required String teacherId,
  required String studentId,
  required String studentName,
}) async {
  final SubscriptionProposal? existing;
  try {
    existing = await ref
        .read(subscriptionProposalRepositoryProvider)
        .getActiveProposal(teacherId, studentId);
  } catch (_) {
    // Lookup failure must not block creation — the BE 409 constraint is the
    // authoritative second line of defense (spec §3.1.5).
    return true;
  }
  if (existing == null) return true;
  if (!context.mounted) return false;

  final action = await showDialog<_DuplicateProposalAction>(
    context: context,
    builder: (_) => _DuplicateProposalDialog(studentName: studentName),
  );

  switch (action) {
    case _DuplicateProposalAction.viewExisting:
      if (context.mounted) {
        context.push(AppRoutes.proposalDetail.replaceFirst(':id', existing.id));
      }
      return false;
    case _DuplicateProposalAction.cancelAndResend:
      await ref
          .read(subscriptionProposalNotifierProvider.notifier)
          .cancel(existing.id);
      return true;
    case null:
      return false;
  }
}

enum _DuplicateProposalAction { viewExisting, cancelAndResend }

class _DuplicateProposalDialog extends StatelessWidget {
  const _DuplicateProposalDialog({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.duplicateProposalDialogTitle,
              style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.duplicateProposalDialogBody(studentName),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
              ),
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(_DuplicateProposalAction.viewExisting),
              child: const Text(AppStrings.duplicateProposalViewExisting),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(_DuplicateProposalAction.cancelAndResend),
              child: const Text(AppStrings.duplicateProposalCancelAndResend),
            ),
          ],
        ),
      ),
    );
  }
}
