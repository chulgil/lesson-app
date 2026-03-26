import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../../schedule/presentation/providers/unified_lesson_request_providers.dart';

/// Displays active lesson request progress cards on the student dashboard.
class UnifiedRequestProgressSection extends ConsumerWidget {
  final String studentId;

  const UnifiedRequestProgressSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(studentUnifiedRequestsProvider(studentId));

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        final activeRequests =
            requests.where((r) => r.isActive).toList();
        if (activeRequests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Text(
                '레슨 신청 진행 중',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            ...activeRequests.map(
              (request) => _RequestProgressCard(request: request),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        );
      },
    );
  }
}

class _RequestProgressCard extends StatelessWidget {
  final UnifiedLessonRequest request;

  const _RequestProgressCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final (statusIcon, statusColor, statusText) = _getStatusDisplay();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.instrument} ${request.type.label}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getStatusDisplay() {
    return switch (request.status) {
      UnifiedRequestStatus.pending => (
          Icons.hourglass_empty,
          AppColors.warning,
          '선생님 확인 중',
        ),
      UnifiedRequestStatus.approved => (
          Icons.check_circle_outline,
          AppColors.success,
          '승인됨',
        ),
      UnifiedRequestStatus.negotiating => (
          Icons.swap_horiz,
          AppColors.info,
          '대안 시간 도착 (${request.currentRound}/3 라운드)',
        ),
      UnifiedRequestStatus.timeConfirmed => (
          Icons.event_available,
          AppColors.success,
          '시간 확정 — 수강권 대기',
        ),
      UnifiedRequestStatus.proposalSent => (
          Icons.mail_outline,
          AppColors.primary,
          '수강권 제안 도착',
        ),
      UnifiedRequestStatus.proposalAccepted => (
          Icons.payment,
          AppColors.primary,
          '결제 대기 중',
        ),
      UnifiedRequestStatus.paymentNotified => (
          Icons.account_balance,
          AppColors.warning,
          '입금 확인 대기',
        ),
      _ => (
          Icons.info_outline,
          AppColors.textSecondaryLight,
          request.status.label,
        ),
    };
  }
}
