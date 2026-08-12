import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../lessons/lessons_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_facade.dart';
import '../../../students/students_ui_facade.dart';
import '../extensions/subscription_visuals.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../utils/expiry_streak_detector.dart';
import '../widgets/expiry_streak_banner.dart';
import '../widgets/next_session_booking_cta.dart';
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

  /// When navigating from a specific lesson, pass the lessonId
  /// so the screen can auto-select the corresponding session.
  final String? focusLessonId;

  /// When arriving from a schedule-change entry point (e.g. the home
  /// dashboard's pending-request section), highlight the bottom response
  /// bar so it reads as "this is why you're here" — parity with the
  /// chat-thread flow's inline response affordance.
  final bool highlightScheduleResponse;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.viewerRole = 'student',
    this.initialSelectedSession,
    this.focusLessonId,
    this.highlightScheduleResponse = false,
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
          focusLessonId: focusLessonId,
          highlightScheduleResponse: highlightScheduleResponse,
        );
      },
      loading:
          () => NotebookScreenScaffold(
            appBar: const NotebookDetailAppBar(
              title: AppStrings.subscriptionDetailTitle,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error: (error, _) => _buildErrorScaffold(error.toString()),
    );
  }

  Widget _buildNotFoundScaffold() {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.subscriptionDetailTitle,
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
      appBar: const NotebookDetailAppBar(
        title: AppStrings.subscriptionDetailTitle,
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
  final String? focusLessonId;
  final bool highlightScheduleResponse;

  const _SubscriptionDetailBody({
    required this.subscription,
    required this.viewerRole,
    this.initialSelectedSession,
    this.focusLessonId,
    this.highlightScheduleResponse = false,
  });

  @override
  ConsumerState<_SubscriptionDetailBody> createState() =>
      _SubscriptionDetailBodyState();
}

class _SubscriptionDetailBodyState
    extends ConsumerState<_SubscriptionDetailBody> {
  late int _selectedSession;
  bool _sessionResolved = false;

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

  /// Resolve focusLessonId → session number using lesson list.
  /// Called once in build() when data is available.
  void _resolveFocusLesson() {
    if (_sessionResolved || widget.focusLessonId == null) return;
    _sessionResolved = true;

    final lessonsAsync = ref.read(
      lessonsByStudentProvider(subscription.studentId),
    );
    final lessons = lessonsAsync.valueOrNull;
    if (lessons == null) return;

    // Filter lessons belonging to this subscription, sorted by date
    final subLessons =
        lessons.where((l) => l.subscriptionId == subscription.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final idx = subLessons.indexWhere((l) => l.id == widget.focusLessonId);
    if (idx >= 0) {
      final totalSessions = subscription.totalLessonsForDisplay ?? 1;
      setState(() {
        _selectedSession = (idx + 1).clamp(1, totalSessions);
      });
    }
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

  /// §8 — 미정 회차 예약: 선생님은 레슨 추가(수강권 프리필), 학생은 직접 예약.
  void _openNextSessionBooking({
    required String studentName,
    required String teacherName,
  }) {
    if (_isTeacher) {
      context.push(
        '${AppRoutes.addLesson}?studentId=${subscription.studentId}'
        '&subscriptionId=${subscription.id}',
      );
      return;
    }
    final teacherId = _getTeacherId();
    if (teacherId == null) return;
    context.push(
      AppRoutes.lessonDirectBooking,
      extra: LessonBookingParams(
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: subscription.studentId,
        studentName: studentName,
        instrument: subscription.instrument,
        subscriptionId: subscription.id,
      ),
    );
  }

  /// Resolve teacherId from membership.
  /// Called in handlers that cannot access local build() variables.
  String? _getTeacherId() {
    final membershipAsync = ref.read(
      membershipProvider(subscription.membershipId),
    );
    final membership = membershipAsync.valueOrNull;
    if (membership == null) return null;

    final lessonClassAsync = ref.read(
      lessonClassProvider(membership.lessonClassId),
    );
    final lessonClass = lessonClassAsync.valueOrNull;
    return lessonClass?.teacherId;
  }

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
    // Resolve focusLessonId → session number (once)
    _resolveFocusLesson();

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
                  () => showStudentProfileBottomSheet(
                    context: context,
                    studentId: subscription.studentId,
                    studentName: studentName,
                    instrument: instrument,
                    student:
                        ref
                            .read(studentProvider(subscription.studentId))
                            .valueOrNull,
                    subscriptionSummary:
                        '${subscription.typeLabel} · ${subscription.remainingLessons ?? 0}/${subscription.totalLessonsForDisplay ?? 0}${AppStrings.remainingCountSuffix}',
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

              // §8 — 미정 회차 예약 진입점 (회차권 전용, 정규권 비노출)
              NextSessionBookingCta(
                subscription: subscription,
                onBook:
                    (nextSession) => _openNextSessionBooking(
                      studentName: studentName,
                      teacherName: teacherName,
                    ),
              ),

              // §7.119 v2.2: 휴강 상단 배너 (선생님+학생 모두 표시)
              _TeacherCancelBanner(subscriptionId: subscription.id),

              // #692 §8.1: 동일 회차 3회 연속 만료 안내 배너
              if (hasConsecutiveExpiryStreak(
                events: sessionEvents,
                sessionNumber: _selectedSession,
              ))
                const ExpiryStreakBanner(),

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
                      () => showStudentProfileBottomSheet(
                        context: context,
                        studentId: subscription.studentId,
                        studentName: studentName,
                        instrument: instrument,
                        student:
                            ref
                                .read(studentProvider(subscription.studentId))
                                .valueOrNull,
                        subscriptionSummary:
                            '${subscription.typeLabel} · ${subscription.remainingLessons ?? 0}/${subscription.totalLessonsForDisplay ?? 0}${AppStrings.remainingCountSuffix}',
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
            highlightResponse: widget.highlightScheduleResponse,
            onScheduleChange: () => _handleScheduleChange(context),
            onAcceptScheduleChoice: _handleAcceptScheduleChoice,
            onRejectScheduleChoice:
                (event, message) =>
                    _handleRejectScheduleChoice(context, event, message),
            onCompareSchedule:
                (event) => _handleCompareSchedule(context, event),
            onWithdrawScheduleDecision:
                (event) => _handleWithdrawScheduleDecision(context, event),
            onCancellationFreeProcess:
                (event) => _handleCancellationFreeProcess(context, event),
            onCancellationAcknowledge: _handleCancellationAcknowledge,
            onCancelLesson:
                _isTeacher ? null : () => _handleCancelLesson(context),
          ),
        );
      },
      loading:
          () => NotebookScreenScaffold(
            appBar: const NotebookDetailAppBar(
              title: AppStrings.subscriptionDetailTitle,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, __) => NotebookScreenScaffold(
            appBar: const NotebookDetailAppBar(
              title: AppStrings.subscriptionDetailTitle,
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
  // Action Handlers
  // ═══════════════════════════════════════════════════════════════

  /// 협상 상대(알림 받는 사람) userId. 내가 선생이면 학생, 학생이면 선생.
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
      actorId:
          _isTeacher
              ? (_getTeacherId() ?? subscription.studentId)
              : subscription.studentId,
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
    // #1191 — 상대 통지는 BE Notification row 가 SSOT (#1200). FE 로컬 알림은
    // 액터 기기 전용이라 상대 통지로 쓸 수 없어 제거함.
    if (mounted) _showSuccess(AppStrings.scheduleChangeAccepted);
  }

  /// N8 (0702 감사) — reject the opponent's schedule proposal. Mirrors
  /// request_detail's 3-action response set; destructive → confirm dialog.
  Future<void> _handleRejectScheduleChoice(
    BuildContext context,
    RequestEvent event,
    String message,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.scheduleChangeRejectConfirmTitle,
      message: AppStrings.scheduleChangeRejectConfirmBody,
      confirmLabel: AppStrings.scheduleChangeReject,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true || !mounted) return;

    final rejectEvent = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: _isTeacher ? ProposerRole.teacher : ProposerRole.student,
      actorId:
          _isTeacher
              ? (_getTeacherId() ?? subscription.studentId)
              : subscription.studentId,
      eventType: RequestEventType.scheduleChangeRejected,
      suggestedSlots: event.suggestedSlots,
      message: message.isEmpty ? null : message,
      sessionNumber: _selectedSession,
      createdAt: DateTime.now(),
    );
    addSubscriptionSessionEvent(
      ref,
      subscription.id,
      _selectedSession,
      rejectEvent,
    );
    // #1191 — FE 로컬 알림(액터 기기 전용) 오발 제거. reject 상대 통지는 전용
    // 타입 부재로 BE emit 미구현 잔여(#1193) — 기존에도 상대 미수신.
    if (mounted) _showSuccess(AppStrings.scheduleChangeReject);
  }

  /// Open schedule comparison screen to counter-propose.
  Future<void> _handleCompareSchedule(
    BuildContext context,
    RequestEvent event,
  ) async {
    final teacherId = _getTeacherId();
    final result = await showSuggestAlternativeBottomSheet(
      context,
      message: '',
      durationMinutes: 60,
      teacherId: teacherId ?? '',
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
      actorId:
          _isTeacher
              ? (_getTeacherId() ?? subscription.studentId)
              : subscription.studentId,
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
    // #1191 — 상대 통지는 BE(#1200 scheduleChangeRequested→교사 emit). FE 로컬
    // 알림은 액터 기기 전용이라 상대 통지로 쓸 수 없어 제거함.
    if (mounted) _showSuccess(AppStrings.alternativeProposeSent);
  }

  /// Withdraw current decision and re-propose via schedule comparison.
  Future<void> _handleWithdrawScheduleDecision(
    BuildContext context,
    RequestEvent event,
  ) async {
    final teacherId = _getTeacherId();
    final result = await showSuggestAlternativeBottomSheet(
      context,
      message: '',
      durationMinutes: 60,
      teacherId: teacherId ?? '',
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

    final teacherId = _getTeacherId();

    // Both single and bulk use the same ScheduleChangeSlotBottomSheet.
    // P0-1 Phase B(b) — 부모가 BottomSheet 흐름이므로 sheet 로 통일.
    final result = await showScheduleChangeSlotBottomSheet(
      context,
      params: ScheduleChangeSlotParams(
        teacherId: teacherId ?? '',
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
      actorId:
          _isTeacher
              ? (_getTeacherId() ?? subscription.studentId)
              : subscription.studentId,
      eventType: RequestEventType.scheduleChangeProposed,
      scheduleChangeType: changeType,
      suggestedSlots: suggestedSlots,
      message: message,
      sessionNumber: _selectedSession,
      createdAt: DateTime.now(),
    );

    addSubscriptionSessionEvent(ref, subscription.id, _selectedSession, event);

    // #1191 — 상대 통지는 BE Notification row 가 SSOT (#1200). FE 로컬 알림은
    // 액터 기기 전용이라 상대 통지로 쓸 수 없어 제거함.

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
      actorId:
          _isTeacher
              ? (_getTeacherId() ?? subscription.studentId)
              : subscription.studentId,
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

  /// Student: open cancel-lesson bottom sheet and record cancellation event.
  Future<void> _handleCancelLesson(BuildContext context) async {
    final reason = await showCancelLessonBottomSheet(context);
    if (reason == null || !mounted) return;

    // Credit policy (lesson_cancellation_flow_spec §2, §3.3, §7, §8.2).
    final now = DateTime.now();
    final lessonStart = _sessionStartTime() ?? now;
    final outcome = const CancellationCreditPolicy().compute(
      reason: reason,
      lessonStart: lessonStart,
      now: now,
      deadlineHours: subscription.effectiveCancelDeadlineHours,
      usedReschedule: subscription.usedRescheduleCount,
      maxReschedule: subscription.effectiveRescheduleAllowance,
    );

    // §8.2: after-deadline student cancel with no credits left → block.
    if (outcome.blocked) {
      _showEventMessage(
        AppStrings.rescheduleCreditsExhausted,
        color: AppColors.paperAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    final event = RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: subscription.id,
      actorType: ProposerRole.student,
      actorId: subscription.studentId,
      eventType: RequestEventType.lessonCancelled,
      message: reason.label,
      sessionNumber: _selectedSession,
      changeCreditUsed: outcome.creditUsed,
      changeCreditRemainingAfter: outcome.remainingAfter,
      keepsSessionNumber: true,
      createdAt: now,
    );

    addSubscriptionSessionEvent(ref, subscription.id, _selectedSession, event);
    if (mounted) {
      _showSuccess(
        outcome.creditUsed > 0
            ? AppStrings.cancelRequestCompletedDeducted
            : AppStrings.cancelRequestCompletedFree,
      );
    }
  }

  /// Resolve the scheduled start datetime of the currently selected session,
  /// combining the lesson's date + "HH:mm" startTime. Null when unknown.
  DateTime? _sessionStartTime() {
    final lessons =
        ref.read(lessonsByStudentProvider(subscription.studentId)).valueOrNull;
    if (lessons == null) return null;
    final subLessons =
        lessons.where((l) => l.subscriptionId == subscription.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final idx = _selectedSession - 1;
    if (idx < 0 || idx >= subLessons.length) return null;
    final lesson = subLessons[idx];
    final parts = lesson.startTime.split(':');
    if (parts.length != 2) return lesson.date;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(
      lesson.date.year,
      lesson.date.month,
      lesson.date.day,
      hour,
      minute,
    );
  }
}

/// v3: 휴강 배너 — TeacherAnnouncement 기반.
/// 선생님/학생 모두에게 표시. 7일 이내 휴강 공지가 있으면 배너 노출.
class _TeacherCancelBanner extends ConsumerWidget {
  final String subscriptionId;

  const _TeacherCancelBanner({required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // teacherId는 현재 사용자 또는 수강권의 선생님
    final teacherId = ref.watch(currentUserIdProvider);
    final now = DateTime.now();
    final dayOffsAsync = ref.watch(
      teacherDayOffsProvider(
        teacherId: teacherId,
        fromDate: now.subtract(const Duration(days: 7)),
        toDate: now.add(const Duration(days: 30)),
      ),
    );
    final dayOffs = dayOffsAsync.valueOrNull ?? const [];
    if (dayOffs.isEmpty) return const SizedBox.shrink();

    // 미래 휴강일만 표시
    final today = DateTime(now.year, now.month, now.day);
    final futureDayOffs =
        dayOffs
            .where((d) => !DateTime(d.year, d.month, d.day).isBefore(today))
            .toList()
          ..sort();

    if (futureDayOffs.isEmpty) return const SizedBox.shrink();

    final dateText =
        futureDayOffs.length == 1
            ? formatDateMD(futureDayOffs.first)
            : '${formatDateMD(futureDayOffs.first)}~${formatDateMD(futureDayOffs.last)}';

    // 공지 메시지 가져오기
    final announcementsAsync = ref.watch(
      teacherAnnouncementsProvider(teacherId),
    );
    final announcements = announcementsAsync.valueOrNull ?? const [];
    final dayOffAnnouncement =
        announcements
            .where((a) => a.type == AnnouncementType.dayOff)
            .firstOrNull;
    final message = dayOffAnnouncement?.message;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '$dateText 휴강',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
