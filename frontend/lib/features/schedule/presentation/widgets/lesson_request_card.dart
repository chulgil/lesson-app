import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';

/// Lesson request card - styled like TrialBookingCard
class LessonRequestCard extends ConsumerWidget {
  final LessonRequest request;

  const LessonRequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending =
        request.status == LessonRequestStatus.pending && !request.isExpired;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info & status
          Row(
            children: [
              // Student avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  _getStudentInitial(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),

              // Student name & time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '레슨요청',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '학생 ${request.studentId.replaceAll('student_', '#')}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _buildStatusBadge(),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Previous schedule info
          if (request.hasPreviousSchedule) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이전 스케줄',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          LessonDateUtils.formatScheduleDisplay(
                            weekday: request.previousLessonDay!,
                            time: request.previousLessonTime!,
                            includeWeekly: true,
                          ),
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (request.keepPreviousSchedule)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '유지 희망',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],

          // Message
          if (request.message != null && request.message!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '메시지',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${request.message}"',
                    style: AppTypography.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],

          // Timing & expiration info
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '희망 시작: ${request.preferredTiming.label}',
                  style: AppTypography.bodyMedium,
                ),
                if (isPending) ...[
                  const Spacer(),
                  Text(
                    request.formattedExpiration,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Decline reason (shown as guidance message)
          if (request.status == LessonRequestStatus.declined &&
              request.declineReason != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안내 메시지',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.declineReason!,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons (for pending requests)
          if (isPending) ...[
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeclineDialog(context, ref),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('다음에'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryLight,
                      side: BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push(
                        '${AppRoutes.issueSubscription}?studentId=${request.studentId}&lessonRequestId=${request.id}',
                      );
                    },
                    icon: const Icon(Icons.card_giftcard, size: 16),
                    label: const Text('수강권 제안'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getStudentInitial() {
    // Extract number from studentId like "student_1" -> "1"
    final number = request.studentId.replaceAll(RegExp(r'[^0-9]'), '');
    return number.isNotEmpty ? number : 'S';
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    String label;

    switch (request.status) {
      case LessonRequestStatus.pending:
        if (request.isExpired) {
          color = AppColors.textSecondaryLight;
          icon = Icons.schedule;
          label = '만료됨';
        } else {
          color = AppColors.warning;
          icon = Icons.hourglass_empty;
          label = '대기 중';
        }
        break;
      case LessonRequestStatus.proposalSent:
        color = AppColors.info;
        icon = Icons.send;
        label = '제안 완료';
        break;
      case LessonRequestStatus.accepted:
        color = AppColors.success;
        icon = Icons.check_circle;
        label = '수락됨';
        break;
      case LessonRequestStatus.declined:
        color = AppColors.error;
        icon = Icons.cancel;
        label = '거절됨';
        break;
      case LessonRequestStatus.expired:
        color = AppColors.textSecondaryLight;
        icon = Icons.schedule;
        label = '만료됨';
        break;
      case LessonRequestStatus.cancelled:
        color = AppColors.textSecondaryLight;
        icon = Icons.cancel;
        label = '취소됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeclineDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('레슨 요청 보류'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('학생에게 전달할 안내 메시지를 입력해주세요. (선택)'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '예: 현재 가능한 시간이 없어 이번에는 어렵습니다.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textSecondaryLight,
                ),
                child: const Text('보류'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(lessonRequestActionsProvider.notifier)
            .declineRequest(
              requestId: request.id,
              reason:
                  reasonController.text.isEmpty
                      ? '현재 스케줄 조정이 어려워요. 다음에 꼭 연락드릴게요!'
                      : reasonController.text,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학생에게 안내 메시지를 전달했습니다'),
              backgroundColor: AppColors.textSecondaryLight,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
