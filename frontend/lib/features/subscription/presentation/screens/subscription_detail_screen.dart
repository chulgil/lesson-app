import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/schedule_guide_info_box.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/subscription_bottom_input_bar.dart';
import '../widgets/subscription_detail_chat_list.dart';
import '../widgets/subscription_policy_sheet.dart';

/// Screen showing subscription detail with progress bar + chat layout.
///
/// Layout matches [RequestDetailScreen]:
/// - AppBar: opponent name (typeLabel) — tap → profile
/// - SessionProgressBar (fixed, matches LessonProgressBar style)
/// - ScheduleGuideInfoBox (fixed)
/// - Scrollable chat area (per-session schedule change events)
/// - Bottom input bar (message send + schedule change)
class SubscriptionDetailScreen extends ConsumerWidget {
  final String subscriptionId;
  final String viewerRole;
  final int? initialSelectedSession;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.viewerRole = 'student',
    this.initialSelectedSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider(subscriptionId));

    return subscriptionAsync.when(
      data: (subscription) {
        if (subscription == null) return _buildNotFoundScaffold();
        return _SubscriptionDetailBody(
          subscription: subscription,
          viewerRole: viewerRole,
          initialSelectedSession: initialSelectedSession,
        );
      },
      loading:
          () => NotebookScreenScaffold(
            appBar: AppBar(
              title: Text(AppStrings.subscriptionDetailTitle),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error: (error, _) => _buildErrorScaffold(error.toString()),
    );
  }

  Widget _buildNotFoundScaffold() {
    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(AppStrings.subscriptionDetailTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space4),
            // Notebook × Score: 빈 상태 헤드라인 3축 통과 (§7.89) — Playfair 승격.
            Text(
              AppStrings.subscriptionNotFound,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(String error) {
    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(AppStrings.subscriptionDetailTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
              const SizedBox(height: AppSpacing.space3),
              // Notebook × Score: 에러 상태 헤드라인 3축 통과 (§7.89) — Playfair 승격.
              Text(
                AppStrings.errorOccurred,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                error,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String subscriptionDetailOpponentName({
  required String viewerRole,
  required String studentName,
  required String teacherName,
}) {
  return viewerRole == 'teacher' ? studentName : teacherName;
}

/// Stateful body with session selection, chat scroll, and bottom input.
class _SubscriptionDetailBody extends ConsumerStatefulWidget {
  final Subscription subscription;
  final String viewerRole;
  final int? initialSelectedSession;

  const _SubscriptionDetailBody({
    required this.subscription,
    required this.viewerRole,
    this.initialSelectedSession,
  });

  @override
  ConsumerState<_SubscriptionDetailBody> createState() =>
      _SubscriptionDetailBodyState();
}

class _SubscriptionDetailBodyState
    extends ConsumerState<_SubscriptionDetailBody> {
  late int _selectedSession;

  // Event strip state — matches RequestDetailScreen pattern exactly
  String? _eventMessage;
  Color _eventColor = AppColors.paperOk;
  IconData _eventIcon = Icons.check_circle;
  Timer? _eventTimer;

  Subscription get subscription => widget.subscription;
  bool get _isTeacher => widget.viewerRole == 'teacher';

  @override
  void initState() {
    super.initState();
    final totalSessions = subscription.totalLessonsForDisplay ?? 1;
    _selectedSession = (widget.initialSelectedSession ??
            subscription.usedLessons + 1)
        .clamp(1, totalSessions);
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    super.dispose();
  }

  void _showEventMessage(
    String message, {
    Color color = AppColors.paperOk,
    IconData icon = Icons.check_circle,
  }) {
    _eventTimer?.cancel();
    setState(() {
      _eventMessage = message;
      _eventColor = color;
      _eventIcon = icon;
    });
    _eventTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _eventMessage = null);
    });
  }

  void _showSuccess(String message) => _showEventMessage(
    message,
    color: AppColors.paperOk,
    icon: Icons.check_circle,
  );

  /// Event strip widget — pixel-exact match with RequestDetailScreen._buildEventStrip()
  Widget _buildEventStrip() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child:
          _eventMessage != null
              ? Container(
                key: ValueKey(_eventMessage),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.space2,
                ),
                color: _eventColor.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Icon(_eventIcon, size: 16, color: _eventColor),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        _eventMessage!,
                        style: AppTypography.caption.copyWith(
                          color: _eventColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _eventMessage = null),
                      child: Icon(Icons.close, size: 14, color: _eventColor),
                    ),
                  ],
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membershipAsync = ref.watch(
      membershipProvider(subscription.membershipId),
    );
    final studentNames = ref.watch(studentNameMapProvider);
    final teacherNames = ref.watch(teacherNameMapProvider);

    return membershipAsync.when(
      data: (membership) {
        final instrument =
            membership?.instrument ?? AppStrings.instrumentFallback;
        final lessonClassAsync =
            membership != null
                ? ref.watch(lessonClassProvider(membership.lessonClassId))
                : null;

        // Schedule-change detail must not look like a lesson request.
        // Keep the same Notebook masthead style, but use the post-issuance
        // schedule-change context as the first readable signal.
        final studentName =
            studentNames[subscription.studentId] ?? AppStrings.student;
        final lessonClass = lessonClassAsync?.valueOrNull;
        final isAcademy = lessonClass?.type.name == 'academy';
        final typeLabel = subscription.typeLabel;
        final teacherName =
            lessonClass == null
                ? AppStrings.teacher
                : teacherNames[lessonClass.teacherId] ?? AppStrings.teacher;
        final opponentName = subscriptionDetailOpponentName(
          viewerRole: widget.viewerRole,
          studentName: studentName,
          teacherName: teacherName,
        );

        final appBarTitle =
            isAcademy && lessonClass != null
                ? '${AppStrings.scheduleChangeTitle} · ${lessonClass.name} $studentName ($typeLabel)'
                : '${AppStrings.scheduleChangeTitle} · $studentName ($typeLabel)';

        // Watch session events for turn-based locking
        final sessionEvents =
            ref
                .watch(
                  subscriptionSessionEventsProvider(
                    subscriptionId: subscription.id,
                    sessionNumber: _selectedSession,
                  ),
                )
                .valueOrNull ??
            [];

        return NotebookScreenScaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            titleSpacing: 0,
            // Notebook × Score: Scaffold.appBar 제목은 Playfair appBarTitle
            // 로 통일 (§7.27). 탭하면 학생 프로필 바텀시트 표시.
            title: GestureDetector(
              onTap:
                  () => _showProfileBottomSheet(
                    context,
                    studentName,
                    instrument,
                    lessonClass,
                  ),
              child: Text(
                appBarTitle,
                style: NotebookTypography.appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.rule_rounded),
                tooltip: AppStrings.policyAppliedTitle,
                onPressed:
                    () => SubscriptionPolicySheet.show(
                      context,
                      subscription: subscription,
                    ),
              ),
            ],
          ),
          body: Column(
            children: [
              // SessionProgressBar (fixed, no wrapper — matches request_detail)
              SessionProgressBar(
                totalSessions: subscription.totalLessonsForDisplay ?? 0,
                completedSessions: subscription.usedLessons,
                selectedSession: _selectedSession,
                isMonthly: subscription.type == SubscriptionType.monthly,
                onSessionTap: (session) {
                  setState(() => _selectedSession = session);
                },
              ),

              // Guide info box (fixed)
              ScheduleGuideInfoBox(
                subscription: subscription,
                isBulkMode: false,
                viewerRole: widget.viewerRole,
              ),

              // Scrollable chat area (schedule change events only)
              Expanded(
                child: SubscriptionDetailChatList(
                  subscription: subscription,
                  selectedSession: _selectedSession,
                  instrument: instrument,
                  viewerRole: widget.viewerRole,
                  studentName: studentName,
                  teacherName: teacherName,
                  onOpponentAvatarTap:
                      () => _showProfileBottomSheet(
                        context,
                        studentName,
                        instrument,
                        lessonClass,
                      ),
                ),
              ),

              // Event feedback strip (above bottom bar) — matches RequestDetailScreen
              _buildEventStrip(),
            ],
          ),
          bottomNavigationBar: SubscriptionBottomInputBar(
            subscription: subscription,
            viewerRole: widget.viewerRole,
            events: sessionEvents,
            opponentName: opponentName,
            selectedSession: _selectedSession,
            onScheduleChange: () => _handleScheduleChange(context),
            onAcceptScheduleChoice: _handleAcceptScheduleChoice,
            onCompareSchedule:
                (event) => _handleCompareSchedule(context, event),
            onWithdrawScheduleDecision:
                (event) => _handleWithdrawScheduleDecision(context, event),
            onCancellationFreeProcess:
                (event) => _handleCancellationFreeProcess(context, event),
            onCancellationAcknowledge: _handleCancellationAcknowledge,
          ),
        );
      },
      loading:
          () => NotebookScreenScaffold(
            appBar: AppBar(
              title: Text(AppStrings.subscriptionDetailTitle),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, __) => NotebookScreenScaffold(
            appBar: AppBar(
              title: Text(AppStrings.subscriptionDetailTitle),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                AppStrings.lessonInfoNotFound,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Profile Bottom Sheet (matches request_detail_screen pattern)
  // ═══════════════════════════════════════════════════════════════

  void _showProfileBottomSheet(
    BuildContext context,
    String studentName,
    String instrument,
    LessonClass? lessonClass,
  ) {
    final student =
        ref.read(studentProvider(subscription.studentId)).valueOrNull;

    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      showHandle: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.paper),
          padding: EdgeInsets.fromLTRB(
            0,
            AppSpacing.space3,
            0,
            MediaQuery.of(ctx).padding.bottom + AppSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Profile avatar + name
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    student?.profileColor ?? AppColors.scheduleMutedBackground,
                child: Text(
                  studentName.isNotEmpty ? studentName[0] : '?',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Student name
              Text(studentName, style: NotebookTypography.pieceTitle),
              const SizedBox(height: AppSpacing.space1),

              // Instrument + class type
              Text(
                [
                  instrument,
                  if (lessonClass != null)
                    lessonClass.type == LessonClassType.academy
                        ? lessonClass.name
                        : AppStrings.individualLesson,
                ].join(' · '),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),

              // Subscription info
              const SizedBox(height: AppSpacing.space3),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: const BoxDecoration(color: AppColors.paperDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subscription.typeLabel} · ${subscription.remainingLessons ?? 0}/${subscription.totalLessonsForDisplay ?? 0}${AppStrings.remainingCountSuffix}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subscription.startDate != null &&
                          subscription.endDate != null) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          '${subscription.startDate!.year}.${subscription.startDate!.month.toString().padLeft(2, '0')} ~ ${subscription.endDate!.year}.${subscription.endDate!.month.toString().padLeft(2, '0')}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Student detail info (if available)
              if (student != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: [
                      if (student.phone != null && student.phone!.isNotEmpty)
                        _profileInfoRow(AppStrings.phoneLabel, student.phone!),
                      if (student.parentPhone != null &&
                          student.parentPhone!.isNotEmpty)
                        _profileInfoRow(
                          AppStrings.parentPhoneLabel,
                          student.parentPhone!,
                        ),
                      _profileInfoRow(
                        AppStrings.levelLabel,
                        student.level.label,
                      ),
                    ],
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

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Action Handlers
  // ═══════════════════════════════════════════════════════════════

  /// Accept a proposed schedule slot.
  void _handleAcceptScheduleChoice(
    RequestEvent event,
    int slotIndex,
    String message,
  ) {
    final acceptEvent = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: _isTeacher ? ProposerRole.teacher : ProposerRole.student,
      actorId: subscription.studentId,
      eventType: RequestEventType.scheduleChangeAccepted,
      suggestedSlots: event.suggestedSlots,
      selectedSlotIndex: slotIndex,
      message: message.isEmpty ? null : message,
      sessionNumber: _selectedSession,
      createdAt: DateTime.now(),
    );
    addSubscriptionSessionEvent(
      ref,
      subscription.id,
      _selectedSession,
      acceptEvent,
    );
    if (mounted) _showSuccess(AppStrings.scheduleChangeAccepted);
  }

  /// Open schedule comparison screen to counter-propose.
  Future<void> _handleCompareSchedule(
    BuildContext context,
    RequestEvent event,
  ) async {
    final result = await Navigator.push<SuggestAlternativeResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) => SuggestAlternativeScreen(
              message: '',
              durationMinutes: 60,
              teacherId: subscription.membershipId,
            ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.slots.isEmpty) return;

    final suggestedSlots =
        result.slots
            .map(
              (s) => TimeSlotOption(
                id: s.id,
                dayOfWeek: s.dayOfWeek,
                startTime:
                    '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
              ),
            )
            .toList();

    final counterEvent = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: _isTeacher ? ProposerRole.teacher : ProposerRole.student,
      actorId: subscription.studentId,
      eventType: RequestEventType.scheduleChangeCountered,
      suggestedSlots: suggestedSlots,
      message: result.message.isEmpty ? null : result.message,
      sessionNumber: _selectedSession,
      createdAt: DateTime.now(),
    );
    addSubscriptionSessionEvent(
      ref,
      subscription.id,
      _selectedSession,
      counterEvent,
    );
    if (mounted) _showSuccess(AppStrings.alternativeProposeSent);
  }

  /// Withdraw current decision and re-propose via schedule comparison.
  Future<void> _handleWithdrawScheduleDecision(
    BuildContext context,
    RequestEvent event,
  ) async {
    final result = await Navigator.push<SuggestAlternativeResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) => SuggestAlternativeScreen(
              message: '',
              durationMinutes: 60,
              teacherId: subscription.membershipId,
            ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.slots.isEmpty) return;

    final suggestedSlots =
        result.slots
            .map(
              (s) => TimeSlotOption(
                id: s.id,
                dayOfWeek: s.dayOfWeek,
                startTime:
                    '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
              ),
            )
            .toList();

    _recordScheduleChangeEvent(
      changeType: ScheduleChangeType.singleLesson,
      suggestedSlots: suggestedSlots,
      message: result.message.isEmpty ? null : result.message,
    );
  }

  /// Schedule change — same flow as RequestDetailScreen._handleScheduleChange:
  /// 1. showScheduleChangeTypeBottomSheet → type selection
  /// 2. showScheduleChangeSlotBottomSheet (single & bulk share same UI)
  void _handleScheduleChange(BuildContext context) async {
    // Step 1: Choose change type
    final changeType = await showScheduleChangeTypeBottomSheet(context);
    if (changeType == null || !context.mounted) return;

    // Both single and bulk use the same ScheduleChangeSlotBottomSheet.
    // P0-1 Phase B(b) — 부모가 BottomSheet 흐름이므로 sheet 로 통일.
    final result = await showScheduleChangeSlotBottomSheet(
      context,
      params: ScheduleChangeSlotParams(
        teacherId: subscription.membershipId, // TODO: resolve teacherId
        studentId: subscription.studentId,
        durationMinutes: 60,
        currentScheduleLabel: AppStrings.sessionNumberLabel(_selectedSession),
        isBulkChange: changeType == ScheduleChangeType.bulkChange,
      ),
    );
    if (result == null || !context.mounted) return;

    // Record schedule change event in chat (with slot data, same as RequestDetailScreen)
    final suggestedSlots =
        result.slots
            .map(
              (s) => TimeSlotOption(
                id: s.id,
                dayOfWeek: s.dayOfWeek,
                startTime:
                    '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
              ),
            )
            .toList();

    _recordScheduleChangeEvent(
      changeType: changeType,
      suggestedSlots: suggestedSlots,
      message: result.message.isEmpty ? null : result.message,
    );
  }

  /// Record a schedule change proposed event and show it in the chat.
  void _recordScheduleChangeEvent({
    required ScheduleChangeType changeType,
    List<TimeSlotOption> suggestedSlots = const [],
    String? message,
  }) {
    final event = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: _isTeacher ? ProposerRole.teacher : ProposerRole.student,
      actorId: subscription.studentId,
      eventType: RequestEventType.scheduleChangeProposed,
      scheduleChangeType: changeType,
      suggestedSlots: suggestedSlots,
      message: message,
      sessionNumber: _selectedSession,
      createdAt: DateTime.now(),
    );

    addSubscriptionSessionEvent(ref, subscription.id, _selectedSession, event);

    if (mounted) {
      _showSuccess(AppStrings.scheduleChangePropose);
    }
  }

  /// Cancellation free process — teacher returns the credit to student.
  Future<void> _handleCancellationFreeProcess(
    BuildContext context,
    RequestEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: AppStrings.cancellationFreeProcess,
            content: Text(AppStrings.cancellationFreeConfirmDialog),
            cancelLabel: AppStrings.cancel,
            onCancel: () => Navigator.pop(ctx, false),
            onConfirm: () => Navigator.pop(ctx, true),
          ),
    );
    if (confirmed != true || !mounted) return;

    final refundEvent = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: ProposerRole.teacher,
      actorId: subscription.studentId,
      eventType: RequestEventType.cancellationCreditRefunded,
      changeCreditUsed: 0,
      changeCreditRemainingAfter:
          (event.changeCreditRemainingAfter ?? 0) +
          (event.changeCreditUsed ?? 1),
      sessionNumber: _selectedSession,
      message: AppStrings.cancellationCreditRefundedChat,
      createdAt: DateTime.now(),
    );
    addSubscriptionSessionEvent(
      ref,
      subscription.id,
      _selectedSession,
      refundEvent,
    );
    if (mounted) _showSuccess(AppStrings.cancellationFreeProcessed);
  }

  /// Cancellation acknowledge — teacher confirms the cancellation (no credit change).
  void _handleCancellationAcknowledge(RequestEvent event) {
    // No-op: cancellation is already confirmed. This just dismisses the bar.
    // The UI will transition back to default when the next event is checked.
    if (mounted) _showSuccess(AppStrings.cancellationAcknowledge);
  }
}
