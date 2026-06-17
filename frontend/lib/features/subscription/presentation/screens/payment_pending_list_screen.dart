import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/pending_payment.dart';
import '../providers/payment_tracking_provider.dart';

/// 선생님 입금 확인 대기 리스트 — #424.
///
/// 그룹 3개 (오늘 만료 / D+3 이상 / D+0~2) + 각 행의 [재발송] + 스와이프 [회수].
/// [입금 확인] 액션은 기존 outstanding flow를 활용 (후속 PR에서 직접 연결).
class PaymentPendingListScreen extends ConsumerWidget {
  const PaymentPendingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(paymentPendingListProvider);

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.paymentPendingListTitle,
      body: pendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text(AppStrings.paymentPendingEmpty));
          }
          return _Sections(items: items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text(AppStrings.paymentPendingEmpty)),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.items});

  final List<PendingPayment> items;

  @override
  Widget build(BuildContext context) {
    final imminent = items.where((e) => e.isImminent).toList();
    final urgent = items.where((e) => e.isUrgent).toList();
    final recent = items.where((e) => !e.isImminent && !e.isUrgent).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      children: [
        if (imminent.isNotEmpty)
          _Group(
            title: AppStrings.paymentPendingSectionImminent,
            items: imminent,
          ),
        if (urgent.isNotEmpty)
          _Group(title: AppStrings.paymentPendingSectionUrgent, items: urgent),
        if (recent.isNotEmpty)
          _Group(title: AppStrings.paymentPendingSectionRecent, items: recent),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});

  final String title;
  final List<PendingPayment> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: Text(
            title,
            style: NotebookTypography.eyebrow.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        ...items.map((p) => _Row(item: p)),
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.item});

  final PendingPayment item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.paymentPendingRevokeLabel,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmRevoke(context, ref),
        ),
      ],
      startActions: [
        if (item.canResend)
          SwipeAction(
            label: AppStrings.swipeActionResend,
            icon: Icons.send_outlined,
            tone: SwipeActionTone.convenience,
            onPressed: () => _resend(context, ref),
          ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.studentName,
                        style: NotebookTypography.sectionTitle.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        item.daysSinceSent == 0
                            ? '방금'
                            : 'D+${item.daysSinceSent}',
                        style: NotebookTypography.eyebrow.copyWith(
                          color: item.isImminent
                              ? AppColors.paperAccent
                              : item.isUrgent
                              ? AppColors.paperTrial
                              : AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '${item.lessonCount ?? 0}회 · ${item.amount}원',
                    style: NotebookTypography.fine.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: item.canResend ? () => _resend(context, ref) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                backgroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.paymentPendingResendLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resend(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(paymentTrackingActionsProvider).resend(item.proposalId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentPendingResendSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString();
      final friendly = message.contains('cooldown') || message.contains('30')
          ? AppStrings.paymentPendingResendCooldown
          : AppStrings.paymentPendingResendFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    }
  }

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => NotebookAlertDialog(
        title: AppStrings.paymentPendingRevokeConfirmTitle,
        content: const Text(AppStrings.paymentPendingRevokeConfirmBody),
        confirmLabel: AppStrings.paymentPendingRevokeLabel,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (result != true || !context.mounted) return;
    try {
      await ref.read(paymentTrackingActionsProvider).revoke(item.proposalId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentPendingRevokeSuccess)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentPendingRevokeFailed)),
      );
    }
  }
}
