import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
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
    final studentNames = ref.watch(studentNameMapProvider);
    final academyNames = ref.watch(academyNameMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.requestDetailTitle),
        centerTitle: true,
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            AppStrings.requestLoadError,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Text(
                AppStrings.requestNotFound,
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
                // Profile card (same as list item layout)
                _buildProfileCard(
                  request,
                  studentNames[request.studentId] ?? AppStrings.student,
                  academyNames[request.academyId],
                ),

                // Current request action box
                CurrentRequestBox(
                  request: request,
                  events: events,
                  viewerRole: viewerRole,
                  opponentName: viewerRole == 'teacher'
                      ? (studentNames[request.studentId] ?? AppStrings.student)
                      : AppStrings.teacher,
                  onAccept: () => _handleAccept(context, ref, request),
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
                  studentName: studentNames[request.studentId] ?? AppStrings.student,
                ),

                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Profile card — same layout as RequestListItem (avatar + source/type + info + status)
  Widget _buildProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
  ) {
    final source = request.isAcademy
        ? (academyName ?? AppStrings.academy)
        : AppStrings.individualLesson;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Student avatar
          CircleAvatar(
            radius: AppSpacing.avatarMedium / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: Text(
              studentName.isNotEmpty ? studentName[0] : '?',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source + type
                Text(
                  '$source ${request.typeDisplayLabel}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                // Name + instrument + goal + level
                Text(
                  '$studentName · ${request.instrument} · ${request.goal.label} · ${request.experience.label}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),

          // Status chip
          _buildStatusBadge(request),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UnifiedLessonRequest request) {
    final color = _statusColor(request.status);
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
        request.statusChipLabel,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
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

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.approveRequest(
        request.id,
        request.teacherId,
        request.studentId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.acceptError)),
        );
      }
    }
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
        title: const Text(AppStrings.cancelRequestTitle),
        content: const Text(AppStrings.cancelRequestMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.no),
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
            child: const Text(AppStrings.cancelRequestAction),
          ),
        ],
      ),
    );
  }
}
