import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/cancel_lesson_bottom_sheet.dart';
import '../widgets/reschedule_bottom_sheet.dart';
import '../widgets/schedule_guide_info_box.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/subscription_bottom_input_bar.dart';
import '../widgets/subscription_detail_chat_list.dart';

/// Screen showing subscription detail with progress bar + chat layout.
///
/// Layout:
/// - AppBar: student/teacher name + instrument
/// - SessionProgressBar (fixed at top)
/// - Scrollable chat area (per-session events)
/// - Bottom input bar (message + schedule change)
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

    return membershipAsync.when(
      data: (membership) {
        final instrument =
            membership?.instrument ?? AppStrings.instrumentFallback;
        final lessonClassAsync = membership != null
            ? ref.watch(lessonClassProvider(membership.lessonClassId))
            : null;

        return Scaffold(
          appBar: _buildAppBar(instrument, lessonClassAsync),
          body: Column(
            children: [
              // SessionProgressBar (fixed at top)
              _buildProgressBarSection(),

              // Guide info box (fixed)
              ScheduleGuideInfoBox(
                subscription: subscription,
                isBulkMode: false,
                viewerRole: widget.viewerRole,
              ),

              // Scrollable chat area
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
            onScheduleChange: () => _handleReschedule(context),
            onLessonComplete: () => _handleLessonComplete(context),
            onCancel: () => _handleCancel(context),
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

  AppBar _buildAppBar(
    String instrument,
    AsyncValue<LessonClass?>? lessonClassAsync,
  ) {
    final className = lessonClassAsync?.valueOrNull?.name;
    final title = className != null ? '$instrument · $className' : instrument;

    return AppBar(
      title: Text(title),
      centerTitle: true,
    );
  }

  Widget _buildProgressBarSection() {
    final total = subscription.totalLessonsForDisplay ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SessionProgressBar(
        totalSessions: total,
        completedSessions: subscription.usedLessons,
        selectedSession: _selectedSession,
        isMonthly: subscription.type == SubscriptionType.monthly,
        onSessionTap: (session) {
          setState(() => _selectedSession = session);
        },
        onBulkChangeTap: () => _handleReschedule(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Action Handlers
  // ═══════════════════════════════════════════════════════════════

  void _handleReschedule(BuildContext context) async {
    final nextLessonTime =
        DateTime.now().add(const Duration(days: 3, hours: 14));

    final result = await showRescheduleBottomSheet(
      context,
      subscription: subscription,
      currentLessonDateTime: nextLessonTime,
      sessionNumber: _selectedSession,
    );

    if (result != null && context.mounted) {
      final String message;
      if (result.changeType == ScheduleChangeType.bulkChange) {
        message = AppStrings.bulkScheduleChangeCompleted;
      } else if (result.usedRescheduleCredit) {
        message = AppStrings.rescheduleRequestCompletedWithCredit;
      } else {
        message = AppStrings.rescheduleRequestCompleted;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _handleCancel(BuildContext context) async {
    final nextLessonTime =
        DateTime.now().add(const Duration(days: 3, hours: 14));

    final result = await showCancelLessonBottomSheet(
      context,
      subscription: subscription,
      lessonDateTime: nextLessonTime,
      sessionNumber: _selectedSession,
    );

    if (result != null && context.mounted) {
      final message = result.reason.deductsLesson
          ? AppStrings.cancelRequestCompletedDeducted
          : AppStrings.cancelRequestCompletedKept;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _handleLessonComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.lessonComplete),
        content: Text(
          AppStrings.sessionCompleted(
            _selectedSession,
            formatDateMDWithDay(DateTime.now()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.lessonCompleted)),
      );
    }
  }
}
