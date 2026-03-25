import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../features/lessons/domain/entities/payment.dart';
import '../../../../lessons/presentation/providers/payment_providers.dart';

/// Bottom sheet showing payment details with actions.
class PaymentDetailSheet extends ConsumerWidget {
  const PaymentDetailSheet({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.space6),
                _buildDetails(),
                const SizedBox(height: AppSpacing.space6),
                _buildActions(context, ref),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            payment.studentName.isNotEmpty ? payment.studentName[0] : '?',
            style: AppTypography.headingSmall.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(payment.studentName, style: AppTypography.headingMedium),
              Text(
                payment.periodDisplay,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        _DetailRow(label: '금액', value: payment.formattedAmount),
        _DetailRow(label: '상태', value: payment.displayStatus),
        _DetailRow(label: '결제수단', value: payment.method.label),
        _DetailRow(label: '레슨 횟수', value: '${payment.lessonCount}회'),
        if (payment.dueDate != null)
          _DetailRow(
            label: '납부기한',
            value: '${payment.dueDate!.month}월 ${payment.dueDate!.day}일',
          ),
        if (payment.studentConfirmed && payment.studentConfirmedAt != null)
          _DetailRow(
            label: '학생 입금완료',
            value: '${payment.studentConfirmedAt!.month}/${payment.studentConfirmedAt!.day} ${payment.studentConfirmedAt!.hour}:${payment.studentConfirmedAt!.minute.toString().padLeft(2, '0')}',
          ),
        if (payment.description != null)
          _DetailRow(label: '메모', value: payment.description!),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payment.status == PaymentStatus.pending) ...[
          // Student confirmed indicator
          if (payment.isAwaitingTeacherConfirmation)
            _StudentConfirmedBanner(),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ref
                    .read(paymentsNotifierProvider.notifier)
                    .markAsCompleted(payment.id);
              },
              icon: const Icon(Icons.check),
              label: const Text('입금 확인'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.practiceGood,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              ),
            ),
          ),
          // Student confirm button (if not already confirmed)
          if (!payment.studentConfirmed) ...[
            const SizedBox(height: AppSpacing.space2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(paymentsNotifierProvider.notifier)
                      .markStudentConfirmed(payment.id);
                },
                icon: Icon(Icons.notifications, color: AppColors.info),
                label: Text('학생 입금완료 알림', style: TextStyle(color: AppColors.info)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.info),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Edit payment
                },
                icon: const Icon(Icons.edit),
                label: const Text('수정'),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _DeleteButton(
                payment: payment,
                onDelete: () async {
                  await ref
                      .read(paymentsNotifierProvider.notifier)
                      .deletePayment(payment.id);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentConfirmedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, size: 20, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '학생이 입금완료를 알렸습니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '계좌 확인 후 입금확인을 눌러주세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.payment, required this.onDelete});

  final Payment payment;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        Navigator.pop(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('결제 삭제'),
            content: const Text('이 결제 내역을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await onDelete();
        }
      },
      icon: Icon(Icons.delete, color: AppColors.error),
      label: Text('삭제', style: TextStyle(color: AppColors.error)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.error),
      ),
    );
  }
}
