import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';

/// Screen for teachers to view and respond to lesson requests.
///
/// Shows pending requests from previous students wanting to resume lessons.
class LessonRequestsScreen extends ConsumerWidget {
  final String teacherId;

  const LessonRequestsScreen({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teacherLessonRequestsProvider(teacherId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('레슨 요청'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('오류가 발생했습니다: $e'),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          // Group by status
          final pending = requests
              .where((r) => r.status == LessonRequestStatus.pending && !r.isExpired)
              .toList();
          final proposalSent = requests
              .where((r) => r.status == LessonRequestStatus.proposalSent)
              .toList();
          final others = requests
              .where((r) =>
                  r.status != LessonRequestStatus.pending &&
                  r.status != LessonRequestStatus.proposalSent)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Pending requests (need action)
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '대기 중',
                  pending.length,
                  AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.space2),
                ...pending.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Proposal sent
              if (proposalSent.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '수강권 제안됨',
                  proposalSent.length,
                  AppColors.info,
                ),
                const SizedBox(height: AppSpacing.space2),
                ...proposalSent.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Other (declined, expired, etc.)
              if (others.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '지난 요청',
                  others.length,
                  AppColors.textSecondaryLight,
                ),
                const SizedBox(height: AppSpacing.space2),
                ...others.map((r) => _buildRequestCard(context, ref, r)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '레슨 요청이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '이전 학생이 레슨을 요청하면\n여기에 표시됩니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    LessonRequest request,
  ) {
    final isPending =
        request.status == LessonRequestStatus.pending && !request.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: isPending
            ? BorderSide(color: AppColors.warning.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Student name + status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '학생 ${request.studentId.replaceAll('student_', '#')}',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimeSince(request.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),

            // Previous schedule info
            if (request.hasPreviousSchedule) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: AppColors.info,
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
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (request.keepPreviousSchedule)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '유지 희망',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
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
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '메시지',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
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

            // Preferred timing
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '희망 시작: ${request.preferredTiming.label}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                if (isPending)
                  Text(
                    request.formattedExpiration,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),

            // Decline reason (shown as guidance message)
            if (request.status == LessonRequestStatus.declined &&
                request.declineReason != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안내 메시지',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.declineReason!,
                      style: AppTypography.bodySmall,
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
                    child: OutlinedButton(
                      onPressed: () => _showDeclineDialog(context, ref, request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                        side: BorderSide(color: AppColors.borderLight),
                      ),
                      child: const Text('다음에'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to subscription proposal screen
                        context.push(
                          '/subscription/issue',
                          extra: {
                            'studentId': request.studentId,
                            'teacherId': request.teacherId,
                            'showScheduleRestoration': true,
                            'lessonRequestId': request.id,
                          },
                        );
                      },
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('수강권 제안'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(LessonRequest request) {
    Color color;
    String label;

    switch (request.status) {
      case LessonRequestStatus.pending:
        if (request.isExpired) {
          color = AppColors.textSecondaryLight;
          label = '만료됨';
        } else {
          color = AppColors.warning;
          label = '대기 중';
        }
        break;
      case LessonRequestStatus.proposalSent:
        color = AppColors.info;
        label = '제안 완료';
        break;
      case LessonRequestStatus.accepted:
        color = AppColors.success;
        label = '수락됨';
        break;
      case LessonRequestStatus.declined:
        color = AppColors.error;
        label = '거절됨';
        break;
      case LessonRequestStatus.expired:
        color = AppColors.textSecondaryLight;
        label = '만료됨';
        break;
      case LessonRequestStatus.cancelled:
        color = AppColors.textSecondaryLight;
        label = '취소됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  Future<void> _showDeclineDialog(
    BuildContext context,
    WidgetRef ref,
    LessonRequest request,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                hintText: '예: 현재 스케줄이 꽉 차서 다음 기회에 연락드릴게요.',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textSecondaryLight,
            ),
            child: const Text('보류'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(lessonRequestActionsProvider.notifier).declineRequest(
              requestId: request.id,
              reason: reasonController.text.isEmpty
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
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
