import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/current_request_box.dart';
import '../widgets/request_history_chat.dart';

/// Detail screen for a single lesson request — Jira-ticket style.
///
/// Layout:
/// - AppBar: request type badge + status
/// - Profile card (student or teacher info)
/// - CurrentRequestBox (action area)
/// - RequestHistoryChat (event timeline)
class RequestDetailScreen extends ConsumerWidget {
  final String requestId;
  final String viewerRole; // 'teacher' or 'student'

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(unifiedRequestByIdProvider(requestId));
    final eventsAsync = ref.watch(requestEventsProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 요청 상세'),
        centerTitle: true,
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '요청을 불러올 수 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Text(
                '요청을 찾을 수 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            );
          }

          final events = eventsAsync.valueOrNull ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile + type badges
                _buildProfileCard(request),

                // Current request action box
                CurrentRequestBox(
                  request: request,
                  events: events,
                  viewerRole: viewerRole,
                  opponentName: viewerRole == 'teacher'
                      ? '학생' // TODO: Fetch student name from student provider
                      : '선생님',
                  onAccept: () => _handleAccept(ref, request),
                  onCounterPropose: () =>
                      _handleCounterPropose(context, request),
                  onModify: () => _handleModify(context, request),
                  onCancel: () => _handleCancel(context, ref, request),
                ),

                // Chat history
                RequestHistoryChat(
                  events: events,
                  viewerId: viewerRole == 'teacher'
                      ? request.teacherId
                      : request.studentId,
                  studentName: '학생', // TODO: Fetch from student provider
                ),

                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Profile card with type/status badges
  Widget _buildProfileCard(UnifiedLessonRequest request) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space1,
            children: [
              _buildBadge(
                request.typeDisplayLabel,
                AppColors.primary,
              ),
              _buildBadge(
                request.statusChipLabel,
                _statusColor(request.status),
              ),
              if (request.isAcademy)
                _buildBadge('학원', AppColors.info),
              if (request.isReturningStudent)
                _buildBadge('재수강', AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Instrument + goal + experience
          Row(
            children: [
              const Icon(Icons.music_note,
                  size: AppSpacing.iconSM, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                request.instrument,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '${request.goal.label} · ${request.experience.label}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          // Preferred slots summary
          if (request.preferredSlots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            ...request.preferredSlots.map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: AppSpacing.iconXS,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '${slot.priority}순위: ${slot.displayLabel}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(UnifiedRequestStatus status) {
    return switch (status) {
      UnifiedRequestStatus.pending => AppColors.warning,
      UnifiedRequestStatus.approved ||
      UnifiedRequestStatus.timeConfirmed =>
        AppColors.success,
      UnifiedRequestStatus.negotiating => AppColors.info,
      UnifiedRequestStatus.completed => AppColors.success,
      UnifiedRequestStatus.rejected ||
      UnifiedRequestStatus.cancelled =>
        AppColors.error,
      UnifiedRequestStatus.expired => AppColors.textTertiaryLight,
      _ => AppColors.textSecondaryLight,
    };
  }

  void _handleAccept(WidgetRef ref, UnifiedLessonRequest request) {
    final actions = UnifiedLessonRequestActions(ref);
    actions.approveRequest(
      request.id,
      request.teacherId,
      request.studentId,
    );
  }

  void _handleCounterPropose(
      BuildContext context, UnifiedLessonRequest request) {
    // TODO: Open existing DeclineBottomSheet (temporary, #216 will redesign)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('다른 시간 제안 (구현 예정)')),
    );
  }

  void _handleModify(BuildContext context, UnifiedLessonRequest request) {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('요청 수정 (구현 예정)')),
    );
  }

  void _handleCancel(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('요청 취소'),
        content: const Text('이 레슨 요청을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final actions = UnifiedLessonRequestActions(ref);
              actions.cancelRequest(
                request.id,
                viewerRole == 'teacher'
                    ? request.teacherId
                    : request.studentId,
                viewerRole == 'teacher'
                    ? ProposerRole.teacher
                    : ProposerRole.student,
                request.teacherId,
                request.studentId,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }
}
