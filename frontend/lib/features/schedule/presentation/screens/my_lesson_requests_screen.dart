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

/// Screen for students to view their sent lesson requests.
///
/// Shows request status: pending, proposal received, declined, expired.
class MyLessonRequestsScreen extends ConsumerWidget {
  final String studentId;

  const MyLessonRequestsScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(studentLessonRequestsProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('내 레슨 요청'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('오류가 발생했습니다.'),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group by status
          final active = requests
              .where((r) => r.status == LessonRequestStatus.pending && !r.isExpired)
              .toList();
          final proposalReceived = requests
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
              // Proposal received (need action) - no header, card shows status
              if (proposalReceived.isNotEmpty) ...[
                ...proposalReceived.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space2),
              ],

              // Active requests (waiting for response) - no header, card shows status
              if (active.isNotEmpty) ...[
                ...active.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space2),
              ],

              // Others (declined, expired, etc.) - keep header for distinction
              if (others.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '지난 요청',
                  others.length,
                  AppColors.textSecondaryLight,
                  Icons.history,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.send_outlined,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '보낸 레슨 요청이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '이전에 레슨받았던 선생님에게\n레슨 요청을 보내보세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space6),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.teacherSearch),
            icon: const Icon(Icons.search),
            label: const Text('선생님 찾기'),
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
    IconData icon,
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.space1),
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
    final isProposalReceived = request.status == LessonRequestStatus.proposalSent;
    final isPending =
        request.status == LessonRequestStatus.pending && !request.isExpired;
    final isDeclined = request.status == LessonRequestStatus.declined;
    final isInactive = !isProposalReceived && !isPending;

    // Build schedule text
    String? scheduleText;
    if (request.hasPreviousSchedule) {
      scheduleText = LessonDateUtils.formatScheduleDisplay(
        weekday: request.previousLessonDay!,
        time: request.previousLessonTime!,
        includeWeekly: true,
      );
      if (request.previousLessonDuration != null) {
        scheduleText += ' (${request.previousLessonDuration}분)';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: isProposalReceived
            ? BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      color: isProposalReceived
          ? AppColors.success.withValues(alpha: 0.05)
          : isInactive
              ? AppColors.surfaceSecondaryLight
              : null,
      child: InkWell(
        onTap: isProposalReceived && request.proposalId != null
            ? () => context.push(
                AppRoutes.proposalDetail.replaceFirst(':id', request.proposalId!))
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Teacher name + status chip
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isInactive
                        ? AppColors.textTertiaryLight.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: isInactive
                          ? AppColors.textTertiaryLight
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      '선생님 ${request.teacherId.replaceAll('teacher_', '#')}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isInactive
                            ? AppColors.textSecondaryLight
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  _buildStatusChip(request),
                ],
              ),

              // Schedule info (simple one line)
              if (scheduleText != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    const SizedBox(width: 36 + AppSpacing.space3), // Align with name
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scheduleText,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],

              // Expiration info for pending
              if (isPending) ...[
                const SizedBox(height: AppSpacing.space1),
                Row(
                  children: [
                    const SizedBox(width: 36 + AppSpacing.space3),
                    Text(
                      request.formattedExpiration,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],

              // Decline reason
              if (isDeclined && request.declineReason != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          request.declineReason!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // CTA for proposal received
              if (isProposalReceived) ...[
                const SizedBox(height: AppSpacing.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '수강권 확인하기',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],

              // Cancel for pending (small text button)
              if (isPending) ...[
                const SizedBox(height: AppSpacing.space2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showCancelDialog(context, ref, request),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '요청 취소',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(LessonRequest request) {
    Color color;
    String label;
    IconData? icon;

    switch (request.status) {
      case LessonRequestStatus.pending:
        if (request.isExpired) {
          color = AppColors.textSecondaryLight;
          label = '만료됨';
        } else {
          color = AppColors.info;
          label = '대기 중';
          icon = Icons.hourglass_empty;
        }
        break;
      case LessonRequestStatus.proposalSent:
        color = AppColors.success;
        label = '제안 도착';
        icon = Icons.card_giftcard;
        break;
      case LessonRequestStatus.accepted:
        color = AppColors.success;
        label = '수락됨';
        icon = Icons.check_circle;
        break;
      case LessonRequestStatus.declined:
        color = AppColors.textSecondaryLight;
        label = '다음 기회에';
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    LessonRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('요청 취소'),
        content: const Text('레슨 요청을 취소하시겠습니까?\n취소 후에도 다시 요청할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(lessonRequestActionsProvider.notifier).cancelRequest(
              request.id,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('요청이 취소되었습니다'),
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
  }
}
