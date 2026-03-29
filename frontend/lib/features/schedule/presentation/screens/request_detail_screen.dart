import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/current_request_box.dart';
import '../widgets/request_history_chat.dart';
import 'suggest_alternative_screen.dart';

/// Detail screen for a single lesson request — Jira-ticket style.
///
/// Layout:
/// - AppBar: request type badge + title + status
/// - Profile card (type-specific: trial=message focus, regular=history summary)
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

    return requestAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            AppStrings.requestLoadError,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
      data: (request) {
        if (request == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                AppStrings.requestNotFound,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }

        final events = eventsAsync.valueOrNull ?? [];
        final studentName =
            studentNames[request.studentId] ?? AppStrings.student;
        final academyName = academyNames[request.academyId];

        // Watch student data for regular lesson profile card
        final studentAsync = ref.watch(studentProvider(request.studentId));

        return Scaffold(
          appBar: _buildAppBar(request),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile card — type-specific
                _buildProfileCard(
                  request,
                  studentName,
                  academyName,
                  studentAsync.valueOrNull,
                ),

                // Current request action box
                CurrentRequestBox(
                  request: request,
                  events: events,
                  viewerRole: viewerRole,
                  opponentName: viewerRole == 'teacher'
                      ? studentName
                      : AppStrings.teacher,
                  onAccept: () => _handleAccept(context, ref, request),
                  onCounterPropose: () =>
                      _handleCounterPropose(context, ref, request),
                  onModify: () => _handleModify(context, request),
                  onCancel: () => _handleCancel(context, ref, request),
                ),

                // Chat history
                RequestHistoryChat(
                  events: events,
                  viewerId: viewerRole == 'teacher'
                      ? request.teacherId
                      : request.studentId,
                  studentName: studentName,
                ),

                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// AppBar with type badge + title
  AppBar _buildAppBar(UnifiedLessonRequest request) {
    final typeColor = request.type == LessonRequestType.trial
        ? AppColors.info
        : AppColors.primary;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              request.typeDisplayLabel,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          const Text(AppStrings.requestDetailTitle),
        ],
      ),
      centerTitle: true,
    );
  }

  /// Profile card — branches by lesson type
  Widget _buildProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
    Student? student,
  ) {
    return request.type == LessonRequestType.trial
        ? _buildTrialProfileCard(request, studentName, academyName)
        : _buildRegularProfileCard(request, studentName, student);
  }

  /// Trial lesson: emphasize student message (first-time student)
  Widget _buildTrialProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
  ) {
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
          // Header row: avatar + info + status
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.instrument} · ${request.experience.label} · ${request.goal.label}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(request),
            ],
          ),

          // Student message (emphasized for trial)
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: AppSpacing.iconSM,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      request.message!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Academy via
          if (request.isAcademy && academyName != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                const Text('🏫', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  AppStrings.viaAcademy(academyName),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Regular lesson: show history summary (returning student)
  Widget _buildRegularProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    Student? student,
  ) {
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
          // Header row: avatar + info + badges
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          studentName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (request.isReturningStudent) ...[
                          const SizedBox(width: AppSpacing.space2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space1 + 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              AppStrings.returning,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.instrument} · ${request.experience.label} · ${request.goal.label}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(request),
            ],
          ),

          // History summary (from Student entity)
          if (student != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: AppSpacing.iconSM,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '${AppStrings.lessonCount(student.totalLessons)} · ${AppStrings.practiceRate(student.practiceRate)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Message (small, below history)
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: AppSpacing.iconXS,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    request.message!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
      UnifiedRequestStatus.completed => AppColors.success,
      UnifiedRequestStatus.paymentNotified => AppColors.error,
      UnifiedRequestStatus.cancelled => AppColors.warning,
      UnifiedRequestStatus.expired => AppColors.warning,
      UnifiedRequestStatus.rejected => AppColors.warning,
      _ => AppColors.textPrimaryLight,
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

  Future<void> _handleCounterPropose(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    // Navigate directly to schedule comparison screen
    final result = await Navigator.push<({String message, List<TimeSlot> slots})>(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestAlternativeScreen(
          message: AppStrings.proposeDefaultMessage,
          durationMinutes: request.preferredDuration,
          teacherId: request.teacherId,
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);

      if (result.slots.isEmpty) {
        // Reject (from reject bottom sheet inside schedule screen)
        await actions.rejectRequest(
          request.id,
          request.teacherId,
          request.studentId,
          reason: result.message,
        );
      } else {
        // Propose alternatives
        await actions.proposeAlternatives(
          request.id,
          request.teacherId,
          request.studentId,
          slots: result.slots
              .map((s) => TimeSlotOption(
                    id: s.id,
                    dayOfWeek: s.dayOfWeek - 1,
                    startTime:
                        '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                    endTime:
                        '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
                  ))
              .toList(),
          message: result.message,
        );
      }

      if (context.mounted) {
        if (result.slots.isNotEmpty) {
          showSuccessSnackBar(context, '대안 시간과 함께 안내가 전달되었습니다');
        } else {
          showInfoSnackBar(context, AppStrings.requestUnavailable);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context);
      }
    }
  }

  void _handleModify(BuildContext context, UnifiedLessonRequest request) {
    // TODO: Navigate to edit screen (requires request edit flow)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('요청 수정 기능은 준비 중입니다')),
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
