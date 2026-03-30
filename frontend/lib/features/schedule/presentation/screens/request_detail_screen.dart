import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/chapter_summary.dart';
import '../../../../core/widgets/lesson_progress_bar.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/lesson_schedule_change.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/schedule_change_response_bottom_sheet.dart';
import 'regular_schedule_change_screen.dart';
import '../widgets/schedule_change_type_bottom_sheet.dart';
import 'schedule_change_slot_screen.dart';
import '../../../subscription/presentation/providers/subscription_template_providers.dart';
import '../widgets/current_request_box.dart';
import '../widgets/proposal_bottom_sheet.dart';
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
  final Set<RequestPhase> _expandedChapters = {};

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

        // Watch teacher templates for Phase 2 proposal display
        final proposalTemplates = ref
            .watch(activeTeacherTemplatesProvider(request.teacherId))
            .valueOrNull ?? [];

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
              // Progress bar (fixed, below AppBar)
              LessonProgressBar(currentPhase: request.currentPhase),

              // Chapter summaries + chat (scrollable)
              Expanded(
                child: ListView(
                  children: [
                    // Completed chapter summaries (collapsed)
                    ..._buildChapterSummaries(request, events),

                    // Chat history (chronological, newest at bottom)
                    RequestHistoryChat(
                      events: _eventsForCurrentPhase(request, events),
                      request: request,
                      shrinkWrap: true,
                      viewerId: viewerRole == 'teacher'
                          ? request.teacherId
                          : request.studentId,
                      studentName: studentName,
                      proposalTemplates: proposalTemplates,
                      onOpponentAvatarTap: () => _showProfileBottomSheet(
                        context,
                        request,
                        opponentName,
                        academyName,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom action bar (phase-aware)
              CurrentRequestBox(
                request: request,
                events: events,
                viewerRole: viewerRole,
                initialSelectedSlot: _preselectedSlot,
                opponentName: opponentName,
                // Phase 1
                onAccept: (slotIndex, message) =>
                    _handleAccept(context, ref, request, slotIndex, message),
                onCounterPropose: () =>
                    _handleCounterPropose(context, ref, request),
                onModify: () => _handleModify(context, request),
                onCancel: () => _handleCancel(context, ref, request),
                onWithdraw: () =>
                    _handleWithdraw(context, ref, request),
                // Phase 2
                onSendPaymentGuide: () =>
                    _handleSendPaymentGuide(context, ref, request),
                onIssuePostpaid: () =>
                    _handleIssuePostpaid(context, ref, request),
                onIssueFree: () =>
                    _handleIssueFree(context, ref, request),
                onConfirmPayment: () =>
                    _handleConfirmPayment(context, ref, request),
                onVerifyPayment: () =>
                    _handleVerifyPayment(context, ref, request),
                onAcceptProposal: (templateId) =>
                    _handleAcceptProposal(context, ref, request, templateId),
                onRejectProposal: (reason) =>
                    _handleRejectProposal(context, ref, request, reason),
                proposalTemplates: proposalTemplates,
                // Phase 3
                onLessonComplete: () =>
                    _handleLessonComplete(context, ref, request),
                onLessonCancel: () =>
                    _handleLessonCancel(context, ref, request),
                onScheduleChange: () =>
                    _handleScheduleChange(context, ref, request),
                onScheduleChangeResponse: () =>
                    _handleScheduleChangeResponse(context, ref, request),
                onAddNote: () =>
                    _handleAddNote(context, ref, request),
                // Phase 4
                onProposeRenewal: () =>
                    _handleRenewal(context, ref, request),
                onRequestRenewal: () =>
                    _handleRenewal(context, ref, request),
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

  /// Bottom sheet with typed profile card (trial vs regular vs student view).
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
      builder: (ctx) {
        // Fetch student data for regular profile card
        final studentAsync = ref.watch(studentProvider(request.studentId));
        final student = studentAsync.valueOrNull;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            0,
            AppSpacing.space3,
            0,
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

              // Typed profile card
              _buildProfileCard(request, opponentName, academyName, student),

              // Student message (quote block for trial, small text for regular)
              if (request.message != null &&
                  request.message!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: request.type == LessonRequestType.trial
                          ? AppColors.primary.withValues(alpha: 0.04)
                          : AppColors.surfaceSecondaryLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                      border: request.type == LessonRequestType.trial
                          ? Border(
                              left: BorderSide(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.type == LessonRequestType.trial)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.space1,
                            ),
                            child: Text(
                              AppStrings.studentMessage,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          request.message!,
                          style: request.type == LessonRequestType.trial
                              ? AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimaryLight,
                                )
                              : AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        );
      },
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

  /// "결정 변경" — opens schedule comparison directly.
  /// No withdraw event until user commits to a change.
  ///
  /// Result handling:
  /// - Same slot + new message → approve event only (message add)
  /// - Different slot → withdraw + approve events
  /// - Propose alternatives → withdraw + propose events
  /// - Reject → withdraw + reject events
  /// - Cancel (back) → nothing happens, approval stays
  Future<void> _handleWithdraw(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    // Find previously approved slot index from events
    final events = await ref.read(
      requestEventsProvider(request.id).future,
    );
    int? prevSlotIndex;
    for (int i = events.length - 1; i >= 0; i--) {
      if ((events[i].eventType == RequestEventType.approve ||
              events[i].eventType == RequestEventType.acceptAlternative) &&
          events[i].selectedSlotIndex != null) {
        prevSlotIndex = events[i].selectedSlotIndex;
        break;
      }
    }

    // Go directly to schedule comparison (no withdraw event yet)
    if (!context.mounted) return;
    final result = await Navigator.push<SuggestAlternativeResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestAlternativeScreen(
          message: '',
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
      final actorRole = viewerRole == 'teacher'
          ? ProposerRole.teacher
          : ProposerRole.student;

      if (result.acceptedSlotIndex != null) {
        // Re-approve: check if slot changed
        final sameSlot = result.acceptedSlotIndex == prevSlotIndex;

        if (sameSlot) {
          // Same slot — just add a new approve event with message (no withdraw)
          await actions.approveRequest(
            request.id,
            request.teacherId,
            request.studentId,
            selectedSlotIndex: result.acceptedSlotIndex,
            message: result.message.isEmpty ? null : result.message,
          );
        } else {
          // Different slot — withdraw first, then approve
          await actions.withdrawApprovalRequest(
            request.id,
            request.teacherId,
            request.studentId,
            actorRole: actorRole,
          );
          await actions.approveRequest(
            request.id,
            request.teacherId,
            request.studentId,
            selectedSlotIndex: result.acceptedSlotIndex,
            message: result.message.isEmpty ? null : result.message,
          );
        }
      } else if (result.slots.isEmpty) {
        // Reject — withdraw + reject
        await actions.withdrawApprovalRequest(
          request.id,
          request.teacherId,
          request.studentId,
          actorRole: actorRole,
        );
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
        // Propose alternatives — withdraw + propose
        await actions.withdrawApprovalRequest(
          request.id,
          request.teacherId,
          request.studentId,
          actorRole: actorRole,
        );
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

  // ── Phase 2 handlers ────────────────────────────────────

  Future<void> _handleSendPaymentGuide(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    // Open proposal bottom sheet with template selection
    final result = await showProposalBottomSheet(
      context,
      teacherId: request.teacherId,
    );
    if (result == null || !context.mounted) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);

      // Build message with template names and bank account
      final templates =
          await ref.read(activeTeacherTemplatesProvider(request.teacherId).future);
      final selectedTemplates = templates
          .where((t) => result.templateIds.contains(t.id))
          .toList();

      final templateSummary = selectedTemplates
          .map((t) => '${t.name} ${t.totalLessons}${AppStrings.lessonsUnit} · ${t.formattedPrice}')
          .join('\n');

      final message = [
        templateSummary,
        if (result.bankAccountDisplay != null)
          '입금계좌: ${result.bankAccountDisplay}',
        if (result.message != null) result.message,
      ].join('\n');

      await actions.sendPaymentGuide(
        request.id,
        request.teacherId,
        request.studentId,
        message: message,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.proposalSend);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleIssuePostpaid(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.issueSubscription(
        request.id,
        request.teacherId,
        request.studentId,
        paymentConfirmed: false,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionIssuePostpaid);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleIssueFree(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.issueSubscription(
        request.id,
        request.teacherId,
        request.studentId,
        paymentConfirmed: true,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionIssueFree);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleConfirmPayment(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.confirmPayment(
        request.id,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionConfirmPayment);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleVerifyPayment(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.issueSubscription(
        request.id,
        request.teacherId,
        request.studentId,
        paymentConfirmed: true,
        message: '입금이 확인되어 수강권이 발급되었습니다',
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionVerifyPayment);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleAcceptProposal(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
    String? selectedTemplateId,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.acceptProposal(
        request.id,
        request.studentId,
        request.teacherId,
        selectedTemplateId: selectedTemplateId,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.eventProposalAccepted);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleRejectProposal(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
    String? reason,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.rejectProposal(
        request.id,
        request.studentId,
        request.teacherId,
        reason: reason,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.eventReject);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  // ── Phase 3 handlers ────────────────────────────────────

  Future<void> _handleLessonComplete(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.recordLessonCompleted(
        request.id,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionLessonComplete);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleLessonCancel(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final actorRole = viewerRole == 'teacher'
        ? ProposerRole.teacher
        : ProposerRole.student;
    final actorId = viewerRole == 'teacher'
        ? request.teacherId
        : request.studentId;

    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.recordLessonCancelled(
        request.id,
        actorId,
        actorRole,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        showInfoSnackBar(context, AppStrings.actionLessonCancel);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleScheduleChange(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final actorRole = viewerRole == 'teacher'
        ? ProposerRole.teacher
        : ProposerRole.student;
    final actorId = viewerRole == 'teacher'
        ? request.teacherId
        : request.studentId;

    // Step 1: Choose change type
    final changeType = await showScheduleChangeTypeBottomSheet(context);
    if (changeType == null || !context.mounted) return;

    if (changeType == ScheduleChangeType.singleLesson) {
      // Step 2a: Navigate to slot selection screen
      final result = await Navigator.of(context).push<ScheduleChangeSlotResult>(
        MaterialPageRoute(
          builder: (_) => ScheduleChangeSlotScreen(
            params: ScheduleChangeSlotParams(
              teacherId: request.teacherId,
              studentId: request.studentId,
              durationMinutes: 60, // TODO: get from subscription
              currentScheduleLabel: request.preferredSlots.isNotEmpty
                  ? request.preferredSlots.first.displayLabel
                  : '-',
            ),
          ),
        ),
      );
      if (result == null || !context.mounted) return;

      // Step 3: Record schedule change proposed event
      try {
        final actions = UnifiedLessonRequestActions(ref);
        await actions.recordScheduleChangeProposed(
          request.id,
          actorId,
          actorRole,
          request.teacherId,
          request.studentId,
          changeType: changeType,
          suggestedSlots: result.slots
              .map((s) => TimeSlotOption(
                    id: s.id,
                    dayOfWeek: s.dayOfWeek,
                    startTime:
                        '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                    endTime:
                        '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
                  ))
              .toList(),
          message: result.message.isEmpty ? null : result.message,
        );
        if (context.mounted) {
          showSuccessSnackBar(context, AppStrings.scheduleChangePropose);
        }
      } catch (e) {
        if (context.mounted) showErrorSnackBar(context);
      }
    } else {
      // Step 2b: Bulk change — navigate to regular schedule change screen
      final regularResult =
          await Navigator.of(context).push<RegularScheduleChangeResult>(
        MaterialPageRoute(
          builder: (_) => RegularScheduleChangeScreen(
            params: RegularScheduleChangeParams(
              currentScheduleLabel: request.preferredSlots.isNotEmpty
                  ? request.preferredSlots.first.displayLabel
                  : '-',
              currentDayOfWeek: request.preferredSlots.isNotEmpty
                  ? request.preferredSlots.first.dayOfWeek
                  : null,
              currentTime: request.preferredSlots.isNotEmpty
                  ? request.preferredSlots.first.startTime
                  : null,
            ),
          ),
        ),
      );
      if (regularResult == null || !context.mounted) return;

      try {
        final actions = UnifiedLessonRequestActions(ref);
        await actions.recordScheduleChangeProposed(
          request.id,
          actorId,
          actorRole,
          request.teacherId,
          request.studentId,
          changeType: changeType,
          proposedDayOfWeek: regularResult.dayOfWeek,
          proposedTime: regularResult.time,
          message: regularResult.message.isEmpty
              ? null
              : regularResult.message,
        );
        if (context.mounted) {
          showSuccessSnackBar(context, AppStrings.scheduleChangePropose);
        }
      } catch (e) {
        if (context.mounted) showErrorSnackBar(context);
      }
    }
  }

  Future<void> _handleScheduleChangeResponse(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final actorRole = viewerRole == 'teacher'
        ? ProposerRole.teacher
        : ProposerRole.student;
    final actorId = viewerRole == 'teacher'
        ? request.teacherId
        : request.studentId;

    // Find the pending proposal's slots and change type
    final events = ref.read(requestEventsProvider(request.id)).valueOrNull ?? [];
    List<TimeSlotOption> proposedSlots = [];
    ScheduleChangeType changeType = ScheduleChangeType.singleLesson;
    for (int i = events.length - 1; i >= 0; i--) {
      final event = events[i];
      if (event.eventType == RequestEventType.scheduleChangeProposed ||
          event.eventType == RequestEventType.scheduleChangeCountered) {
        proposedSlots = event.suggestedSlots;
        changeType = event.scheduleChangeType ?? ScheduleChangeType.singleLesson;
        break;
      }
    }

    final result = await showScheduleChangeResponseBottomSheet(
      context,
      proposedSlots: proposedSlots,
      changeType: changeType,
      durationMinutes: 60,
      teacherId: request.teacherId,
    );
    if (result == null || !context.mounted) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);

      switch (result.action) {
        case ScheduleChangeResponseAction.accept:
          await actions.recordScheduleChangeAccepted(
            request.id,
            actorId,
            actorRole,
            request.teacherId,
            request.studentId,
            selectedSlotIndex: result.acceptedSlotIndex,
            message: result.message.isEmpty ? null : result.message,
          );
          if (context.mounted) {
            showSuccessSnackBar(context, AppStrings.scheduleChangeConfirmed);
          }

        case ScheduleChangeResponseAction.reject:
          await actions.recordScheduleChangeRejected(
            request.id,
            actorId,
            actorRole,
            request.teacherId,
            request.studentId,
            message: result.message.isEmpty ? null : result.message,
          );
          if (context.mounted) {
            showSuccessSnackBar(context, AppStrings.scheduleChangeReject);
          }

        case ScheduleChangeResponseAction.counter:
          await actions.recordScheduleChangeCountered(
            request.id,
            actorId,
            actorRole,
            request.teacherId,
            request.studentId,
            changeType: changeType,
            suggestedSlots: result.counterSlots
                .map((s) => TimeSlotOption(
                      id: s.id,
                      dayOfWeek: s.dayOfWeek,
                      startTime:
                          '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                      endTime:
                          '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
                    ))
                .toList(),
            message: result.message.isEmpty ? null : result.message,
          );
          if (context.mounted) {
            showSuccessSnackBar(context, AppStrings.scheduleChangeCounter);
          }
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  Future<void> _handleAddNote(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.recordLessonNote(
        request.id,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, AppStrings.actionAddNote);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  // ── Phase 4 handler ─────────────────────────────────────

  Future<void> _handleRenewal(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final actorRole = viewerRole == 'teacher'
        ? ProposerRole.teacher
        : ProposerRole.student;
    final actorId = viewerRole == 'teacher'
        ? request.teacherId
        : request.studentId;

    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.renewSubscription(
        request.id,
        actorId,
        actorRole,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          viewerRole == 'teacher'
              ? AppStrings.actionProposeRenewal
              : AppStrings.actionRequestRenewal,
        );
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context);
    }
  }

  // ── Chapter Model Helpers ─────────────────────────────────

  /// Build collapsed chapter summaries for completed phases.
  List<Widget> _buildChapterSummaries(
    UnifiedLessonRequest request,
    List<RequestEvent> events,
  ) {
    final phase = request.currentPhase;
    final chapters = <Widget>[];

    // Phase 1: 레슨 신청 — show as collapsed if past Phase 1
    if (phase != RequestPhase.request && phase != RequestPhase.terminal) {
      final isExpanded = _expandedChapters.contains(RequestPhase.request);
      chapters.add(ChapterSummary(
        icon: Icons.send,
        title: AppStrings.chapterRequest,
        completedDate: _phaseCompletedDate(request, RequestPhase.request),
        summary: _phaseSummary(request, events, RequestPhase.request),
        isExpanded: isExpanded,
        onTap: () => setState(() {
          if (isExpanded) {
            _expandedChapters.remove(RequestPhase.request);
          } else {
            _expandedChapters.add(RequestPhase.request);
          }
        }),
        child: isExpanded
            ? RequestHistoryChat(
                events: _eventsForPhase(events, RequestPhase.request),
                request: request,
                shrinkWrap: true,
                viewerId: viewerRole == 'teacher'
                    ? request.teacherId
                    : request.studentId,
                studentName: '',
              )
            : null,
      ));
    }

    // Phase 2: 수강권 & 결제 — show if past Phase 2
    if (_isPhaseCompleted(phase, RequestPhase.subscription)) {
      final isExpanded =
          _expandedChapters.contains(RequestPhase.subscription);
      chapters.add(ChapterSummary(
        icon: Icons.credit_card,
        title: AppStrings.chapterSubscription,
        completedDate:
            _phaseCompletedDate(request, RequestPhase.subscription),
        summary:
            _phaseSummary(request, events, RequestPhase.subscription),
        isExpanded: isExpanded,
        onTap: () => setState(() {
          if (isExpanded) {
            _expandedChapters.remove(RequestPhase.subscription);
          } else {
            _expandedChapters.add(RequestPhase.subscription);
          }
        }),
      ));
    }

    // Phase 3: 레슨 진행 — show as active header if current
    if (phase == RequestPhase.lessons || phase == RequestPhase.completed) {
      final isActive = phase == RequestPhase.lessons;
      chapters.add(ChapterSummary(
        icon: Icons.music_note,
        title: AppStrings.chapterLessons,
        isActive: isActive,
        summary: isActive ? null : _phaseSummary(request, events, RequestPhase.lessons),
        completedDate: isActive
            ? null
            : _phaseCompletedDate(request, RequestPhase.lessons),
      ));
    }

    return chapters;
  }

  /// Filter events belonging to the current active phase.
  List<RequestEvent> _eventsForCurrentPhase(
    UnifiedLessonRequest request,
    List<RequestEvent> events,
  ) {
    final phase = request.currentPhase;
    // For request phase (Phase 1) or terminal, show all events
    if (phase == RequestPhase.request || phase == RequestPhase.terminal) {
      return events;
    }
    return _eventsForPhase(events, phase);
  }

  /// Get events that belong to a specific phase.
  List<RequestEvent> _eventsForPhase(
    List<RequestEvent> events,
    RequestPhase phase,
  ) {
    return events.where((e) => _eventBelongsToPhase(e, phase)).toList();
  }

  /// Check if an event belongs to a given phase.
  bool _eventBelongsToPhase(RequestEvent event, RequestPhase phase) {
    return switch (phase) {
      RequestPhase.request => const {
          RequestEventType.initialRequest,
          RequestEventType.approve,
          RequestEventType.reject,
          RequestEventType.proposeAlternative,
          RequestEventType.counterPropose,
          RequestEventType.acceptAlternative,
          RequestEventType.withdrawApproval,
          RequestEventType.cancel,
          RequestEventType.expire,
          RequestEventType.proposalSent,
          RequestEventType.proposalAccepted,
          RequestEventType.paymentNotified,
        }.contains(event.eventType),
      RequestPhase.subscription => const {
          RequestEventType.paymentRequested,
          RequestEventType.paymentConfirmed,
          RequestEventType.subscriptionIssued,
        }.contains(event.eventType),
      RequestPhase.lessons => const {
          RequestEventType.lessonCompleted,
          RequestEventType.lessonCancelled,
          RequestEventType.scheduleChanged,
          RequestEventType.lessonNoteAdded,
        }.contains(event.eventType),
      RequestPhase.completed => const {
          RequestEventType.subscriptionRenewed,
          RequestEventType.subscriptionCompleted,
          RequestEventType.completed,
        }.contains(event.eventType),
      RequestPhase.terminal => true,
    };
  }

  /// Whether a phase is fully completed (current phase is past it).
  bool _isPhaseCompleted(RequestPhase current, RequestPhase target) {
    const order = [
      RequestPhase.request,
      RequestPhase.subscription,
      RequestPhase.lessons,
      RequestPhase.completed,
    ];
    final currentIdx = order.indexOf(current);
    final targetIdx = order.indexOf(target);
    if (currentIdx == -1 || targetIdx == -1) return false;
    return currentIdx > targetIdx;
  }

  /// Get a display date for when a phase was completed.
  String? _phaseCompletedDate(
    UnifiedLessonRequest request,
    RequestPhase phase,
  ) {
    if (phase == RequestPhase.request && request.confirmedAt != null) {
      final d = request.confirmedAt!;
      return '${d.month}/${d.day}';
    }
    return null;
  }

  /// Generate a one-line summary for a collapsed chapter.
  String? _phaseSummary(
    UnifiedLessonRequest request,
    List<RequestEvent> events,
    RequestPhase phase,
  ) {
    switch (phase) {
      case RequestPhase.request:
        return request.typeDisplayLabel;
      case RequestPhase.subscription:
        return AppStrings.subscription;
      case RequestPhase.lessons:
        final completedCount = events
            .where((e) => e.eventType == RequestEventType.lessonCompleted)
            .length;
        if (completedCount > 0) return '$completedCount회 완료';
        return null;
      case RequestPhase.completed:
      case RequestPhase.terminal:
        return null;
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
