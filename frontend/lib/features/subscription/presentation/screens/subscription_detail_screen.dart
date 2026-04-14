import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../schedule/presentation/screens/regular_schedule_change_screen.dart';
import '../../../schedule/presentation/screens/schedule_change_slot_screen.dart';
import '../../../schedule/presentation/widgets/schedule_change_type_bottom_sheet.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/schedule_guide_info_box.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/subscription_bottom_input_bar.dart';
import '../widgets/subscription_detail_chat_list.dart';

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

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.viewerRole = 'student',
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
        );
      },
      loading: () => Scaffold(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.subscriptionDetailTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.subscriptionNotFound,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(String error) {
    return Scaffold(
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
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text(AppStrings.errorOccurred, style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.space2),
              Text(
                error,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
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

/// Stateful body with session selection, chat scroll, and bottom input.
class _SubscriptionDetailBody extends ConsumerStatefulWidget {
  final Subscription subscription;
  final String viewerRole;

  const _SubscriptionDetailBody({
    required this.subscription,
    required this.viewerRole,
  });

  @override
  ConsumerState<_SubscriptionDetailBody> createState() =>
      _SubscriptionDetailBodyState();
}

class _SubscriptionDetailBodyState
    extends ConsumerState<_SubscriptionDetailBody> {
  late int _selectedSession;
  final TextEditingController _messageController = TextEditingController();

  Subscription get subscription => widget.subscription;
  bool get _isTeacher => widget.viewerRole == 'teacher';

  @override
  void initState() {
    super.initState();
    _selectedSession = (subscription.usedLessons + 1).clamp(
      1,
      subscription.totalLessonsForDisplay ?? 1,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membershipAsync =
        ref.watch(membershipProvider(subscription.membershipId));
    final studentNames = ref.watch(studentNameMapProvider);
    final academyNames = ref.watch(academyNameMapProvider);

    return membershipAsync.when(
      data: (membership) {
        final instrument =
            membership?.instrument ?? AppStrings.instrumentFallback;
        final lessonClassAsync = membership != null
            ? ref.watch(lessonClassProvider(membership.lessonClassId))
            : null;

        // Build AppBar title — matches RequestDetailScreen format:
        // "학원이름 학생이름 (타입)" or "학생이름 (타입)"
        final studentName =
            studentNames[subscription.studentId] ?? AppStrings.student;
        final lessonClass = lessonClassAsync?.valueOrNull;
        final isAcademy =
            lessonClass?.type.name == 'academy';
        final typeLabel = subscription.typeLabel;

        final appBarTitle = isAcademy && lessonClass != null
            ? '${lessonClass.name} $studentName ($typeLabel)'
            : '$studentName ($typeLabel)';

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(
              appBarTitle,
              style: AppTypography.headingSmall,
            ),
          ),
          body: Column(
            children: [
              // SessionProgressBar (fixed, no wrapper — matches request_detail)
              SessionProgressBar(
                totalSessions:
                    subscription.totalLessonsForDisplay ?? 0,
                completedSessions: subscription.usedLessons,
                selectedSession: _selectedSession,
                isMonthly:
                    subscription.type == SubscriptionType.monthly,
                onSessionTap: (session) {
                  setState(() => _selectedSession = session);
                },
                onBulkChangeTap: () => _handleScheduleChange(context),
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
                ),
              ),
            ],
          ),
          bottomNavigationBar: SubscriptionBottomInputBar(
            subscription: subscription,
            viewerRole: widget.viewerRole,
            messageController: _messageController,
            onSendMessage: _handleSendMessage,
            onScheduleChange: () => _handleScheduleChange(context),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.subscriptionDetailTitle),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.subscriptionDetailTitle),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            AppStrings.lessonInfoNotFound,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Action Handlers
  // ═══════════════════════════════════════════════════════════════

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // TODO: Send message to student via provider
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.messageSentSuccess)),
    );
  }

  /// Schedule change — same flow as RequestDetailScreen._handleScheduleChange:
  /// 1. showScheduleChangeTypeBottomSheet → type selection
  /// 2a. ScheduleChangeSlotScreen (single)
  /// 2b. RegularScheduleChangeScreen (bulk)
  void _handleScheduleChange(BuildContext context) async {
    // Step 1: Choose change type
    final changeType = await showScheduleChangeTypeBottomSheet(context);
    if (changeType == null || !context.mounted) return;

    if (changeType == ScheduleChangeType.singleLesson) {
      // Step 2a: Navigate to slot selection screen
      final result =
          await Navigator.of(context).push<ScheduleChangeSlotResult>(
        MaterialPageRoute(
          builder: (_) => ScheduleChangeSlotScreen(
            params: ScheduleChangeSlotParams(
              teacherId: subscription.membershipId, // TODO: resolve teacherId
              studentId: subscription.studentId,
              durationMinutes: 60,
              currentScheduleLabel:
                  '${_selectedSession}${AppStrings.sessionNumberLabel(_selectedSession)}',
            ),
          ),
        ),
      );
      if (result == null || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.scheduleChangePropose)),
      );
    } else {
      // Step 2b: Bulk change — regular schedule change screen
      final regularResult =
          await Navigator.of(context).push<RegularScheduleChangeResult>(
        MaterialPageRoute(
          builder: (_) => const RegularScheduleChangeScreen(
            params: RegularScheduleChangeParams(
              currentScheduleLabel: '-',
            ),
          ),
        ),
      );
      if (regularResult == null || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.scheduleChangePropose)),
      );
    }
  }
}
