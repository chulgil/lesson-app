import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/current_request_box.dart';
import '../widgets/request_history_chat.dart';
import 'suggest_alternative_screen.dart';

/// Detail screen for a single lesson request — chat-style layout.
///
/// Layout:
/// - AppBar: opponent avatar + name + type + status (tap → student detail)
/// - Chat history (scrollable, chronological, newest at bottom)
/// - Bottom bar: compact slot selection + message input + action buttons
class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String viewerRole; // 'teacher' or 'student'

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.viewerRole,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  int? _preselectedSlot;

  String get viewerRole => widget.viewerRole;
  String get requestId => widget.requestId;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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

        final opponentName = viewerRole == 'teacher'
            ? studentName
            : AppStrings.teacher;

        return Scaffold(
          appBar: _buildChatAppBar(
            context,
            request,
            opponentName,
            academyName,
          ),
          body: Column(
            children: [
              // Chat history (scrollable, chronological)
              Expanded(
                child: RequestHistoryChat(
                  events: events,
                  request: request,
                  viewerId: viewerRole == 'teacher'
                      ? request.teacherId
                      : request.studentId,
                  studentName: studentName,
                  onOpponentAvatarTap: () => _showProfileBottomSheet(
                    context,
                    request,
                    opponentName,
                    academyName,
                  ),
                ),
              ),

              // Bottom action bar (fixed, chat-input style)
              CurrentRequestBox(
                request: request,
                events: events,
                viewerRole: viewerRole,
                initialSelectedSlot: _preselectedSlot,
                opponentName: opponentName,
                onAccept: (slotIndex, message) =>
                    _handleAccept(context, ref, request, slotIndex, message),
                onCounterPropose: () =>
                    _handleCounterPropose(context, ref, request),
                onModify: () => _handleModify(context, request),
                onCancel: () => _handleCancel(context, ref, request),
                onWithdraw: () =>
                    _handleWithdraw(context, ref, request),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Simple AppBar: "< 스케줄요청 박지호 (정규레슨)"
  /// Tap name → bottom sheet profile
  AppBar _buildChatAppBar(
    BuildContext context,
    UnifiedLessonRequest request,
    String opponentName,
    String? academyName,
  ) {
    return AppBar(
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => _showProfileBottomSheet(
          context,
          request,
          opponentName,
          academyName,
        ),
        child: Text(
          request.isAcademy && academyName != null
              ? '$academyName $opponentName (${request.typeDisplayLabel})'
              : '$opponentName (${request.typeDisplayLabel})',
          style: AppTypography.headingSmall,
        ),
      ),
    );
  }

  /// Bottom sheet with opponent profile info (slides up like metronome)
  void _showProfileBottomSheet(
    BuildContext context,
    UnifiedLessonRequest request,
    String opponentName,
    String? academyName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLarge),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.space3,
          AppSpacing.screenPadding,
          MediaQuery.of(ctx).padding.bottom + AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Avatar + name
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              child: Text(
                opponentName.isNotEmpty ? opponentName[0] : '?',
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              opponentName,
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),

            // Type + instrument + level
            Text(
              '${request.typeDisplayLabel} · ${request.instrument} · ${request.experience.label} · ${request.goal.label}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),

            // Academy
            if (request.isAcademy && academyName != null) ...[
              const SizedBox(height: AppSpacing.space1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏫', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    academyName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],

            // Status + elapsed time
            const SizedBox(height: AppSpacing.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusBadge(request),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  formatRelativeTime(request.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),

            // Message (if any)
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Text(
                  request.message!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  /// Profile card — branches by viewer role and lesson type
  Widget _buildProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
    Student? student,
  ) {
    if (viewerRole == 'student') {
      return _buildStudentViewProfileCard(request);
    }
    return request.type == LessonRequestType.trial
        ? _buildTrialProfileCard(request, studentName, academyName)
        : _buildRegularProfileCard(request, studentName, academyName, student);
  }

  /// Trial lesson profile card (first-time student)
  Widget _buildTrialProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
  ) {
    final urgent = isRequestUrgent(request.createdAt);

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
          // Top row: (academy icon + name |OR| 개인레슨) + type + elapsed time
          _buildTopInfoRow(request, academyName, urgent),
          const SizedBox(height: AppSpacing.space3),

          // Student info row: avatar + name + instrument + status
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
        ],
      ),
    );
  }

  /// Regular lesson profile card (returning student)
  Widget _buildRegularProfileCard(
    UnifiedLessonRequest request,
    String studentName,
    String? academyName,
    Student? student,
  ) {
    final urgent = isRequestUrgent(request.createdAt);

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
          // Top row: academy/source + type + elapsed time
          _buildTopInfoRow(request, academyName, urgent),
          const SizedBox(height: AppSpacing.space3),

          // Student info row: avatar + name + instrument + status
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
        ],
      ),
    );
  }

  /// Student view: shows request summary (teacher perspective → student sees what they sent)
  Widget _buildStudentViewProfileCard(UnifiedLessonRequest request) {
    final urgent = isRequestUrgent(request.createdAt);

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
          // Top row: source + type + elapsed time
          _buildTopInfoRow(request, null, urgent),
          const SizedBox(height: AppSpacing.space3),

          // Request info: teacher name + instrument + status
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarMedium / 2,
                backgroundColor: AppColors.info.withValues(alpha: 0.08),
                child: Text(
                  AppStrings.teacher[0],
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.teacher,
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
        ],
      ),
    );
  }

  /// Top info row: 🏫 학원명 | 개인레슨  +  타입  +  경과시간
  Widget _buildTopInfoRow(
    UnifiedLessonRequest request,
    String? academyName,
    bool urgent,
  ) {
    return Row(
      children: [
        // Source: academy icon + name, or "개인레슨"
        if (request.isAcademy && academyName != null) ...[
          const Text('🏫', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              academyName,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ] else ...[
          Text(
            AppStrings.individualLesson,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        // Type badge
        _buildTypeBadge(request),
        // Returning badge (if applicable)
        if (request.isReturningStudent) ...[
          const SizedBox(width: AppSpacing.space1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space1 + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
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
        const Spacer(),
        // Elapsed time
        Text(
          formatRelativeTime(request.createdAt),
          style: AppTypography.caption.copyWith(
            color: urgent ? AppColors.error : AppColors.textTertiaryLight,
            fontWeight: urgent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Type badge: [체험] or [정규] etc.
  Widget _buildTypeBadge(UnifiedLessonRequest request) {
    final typeColor = request.type == LessonRequestType.trial
        ? AppColors.info
        : AppColors.primary;

    return Container(
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
    int selectedSlotIndex,
    String message,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      final msg = message.isEmpty ? null : message;
      if (viewerRole == 'teacher') {
        await actions.approveRequest(
          request.id,
          request.teacherId,
          request.studentId,
          selectedSlotIndex: selectedSlotIndex,
          message: msg,
        );
      } else {
        await actions.acceptAlternativeRequest(
          request.id,
          request.teacherId,
          request.studentId,
          selectedSlotIndex: selectedSlotIndex,
          message: msg,
        );
      }
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
    // Navigate to schedule comparison screen with student's preferred slots
    final result = await Navigator.push<SuggestAlternativeResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestAlternativeScreen(
          message: AppStrings.proposeDefaultMessage,
          durationMinutes: request.preferredDuration,
          teacherId: request.teacherId,
          preferredSlots: request.preferredSlots,
          isStudentView: viewerRole == 'student',
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);

      if (result.acceptedSlotIndex != null) {
        // Approve directly from schedule comparison (inline completion)
        await _handleAccept(
          context,
          ref,
          request,
          result.acceptedSlotIndex!,
          result.message,
        );
        return;
      } else if (result.slots.isEmpty) {
        // Reject (from reject bottom sheet inside schedule screen)
        await actions.rejectRequest(
          request.id,
          request.teacherId,
          request.studentId,
          reason: result.message,
        );
        if (context.mounted) {
          showInfoSnackBar(context, AppStrings.requestUnavailable);
        }
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
                    date: s.specificDate,
                  ))
              .toList(),
          message: result.message,
        );
        if (context.mounted) {
          showSuccessSnackBar(context, AppStrings.alternativeProposeSent);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context);
      }
    }
  }

  Future<void> _handleWithdraw(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.withdrawApproval),
        content: const Text(AppStrings.withdrawApprovalMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.withdrawApproval),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.withdrawApprovalRequest(
        request.id,
        request.teacherId,
        request.studentId,
        actorRole: viewerRole == 'teacher'
            ? ProposerRole.teacher
            : ProposerRole.student,
      );
      if (context.mounted) {
        showInfoSnackBar(context, AppStrings.withdrawApprovalSuccess);
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
      const SnackBar(content: Text(AppStrings.modifyRequestPreparing)),
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
