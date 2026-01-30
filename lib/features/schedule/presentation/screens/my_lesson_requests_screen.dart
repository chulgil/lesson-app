import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        error: (e, _) => Center(
          child: Text('오류가 발생했습니다: $e'),
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
              // Proposal received (need action)
              if (proposalReceived.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '수강권 제안 도착',
                  proposalReceived.length,
                  AppColors.success,
                  Icons.card_giftcard,
                ),
                const SizedBox(height: AppSpacing.space2),
                ...proposalReceived.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Active requests (waiting for response)
              if (active.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  '응답 대기 중',
                  active.length,
                  AppColors.info,
                  Icons.hourglass_empty,
                ),
                const SizedBox(height: AppSpacing.space2),
                ...active.map((r) => _buildRequestCard(context, ref, r)),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Others (declined, expired, etc.)
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
            onPressed: () => context.push('/search'),
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: isProposalReceived
            ? BorderSide(color: AppColors.success.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isProposalReceived && request.proposalId != null
            ? () {
                // Navigate to proposal detail
                context.push('/subscription/proposal/${request.proposalId}');
              }
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Teacher name + status
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
                          '선생님 ${request.teacherId.replaceAll('teacher_', '#')}',
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
                              '요청한 스케줄',
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
                            '유지 요청',
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

              // My message
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
                        '보낸 메시지',
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

              // Preferred timing + expiration
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
                      Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: AppSpacing.space1),
                          Text(
                            '선생님 안내',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

              // Action buttons
              if (isProposalReceived) ...[
                const SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (request.proposalId != null) {
                        context.push('/subscription/proposal/${request.proposalId}');
                      }
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('수강권 제안 확인하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              // Declined - show alternative action
              if (request.status == LessonRequestStatus.declined) ...[
                const SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('다른 선생님 찾아보기'),
                  ),
                ),
              ],

              // Cancel button for pending requests
              if (isPending) ...[
                const SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showCancelDialog(context, ref, request),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryLight,
                    ),
                    child: const Text('요청 취소'),
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

  String _formatTimeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전 요청';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전 요청';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전 요청';
    }
    return '방금 요청';
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
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
