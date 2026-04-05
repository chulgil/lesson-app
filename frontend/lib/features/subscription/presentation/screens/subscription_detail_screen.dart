import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/widgets/chapter_summary.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../utils/subscription_status_colors.dart';
import '../widgets/cancel_lesson_bottom_sheet.dart';
import '../widgets/reschedule_bottom_sheet.dart';
import '../widgets/subscription_action_box.dart';
import '../widgets/subscription_chapter_info.dart';
import '../widgets/subscription_chapter_lessons.dart';
import '../widgets/subscription_chapter_payment.dart';

/// Screen showing subscription detail with chapter model layout.
///
/// Chapter 1: 수강권 정보 (collapsed)
/// Chapter 2: 결제 내역 (collapsed)
/// Chapter 3: 레슨 진행 (expanded — primary)
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
        return _SubscriptionChapterDetail(
          subscription: subscription,
          viewerRole: viewerRole,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppStrings.subscriptionDetailTitle), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildErrorScaffold(error.toString()),
    );
  }

  Widget _buildNotFoundScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.subscriptionDetailTitle), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textTertiaryLight),
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
      appBar: AppBar(title: Text(AppStrings.subscriptionDetailTitle), centerTitle: true),
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

/// Stateful chapter detail with expand/collapse state.
class _SubscriptionChapterDetail extends ConsumerStatefulWidget {
  final Subscription subscription;
  final String viewerRole;

  const _SubscriptionChapterDetail({
    required this.subscription,
    this.viewerRole = 'student',
  });

  @override
  ConsumerState<_SubscriptionChapterDetail> createState() =>
      _SubscriptionChapterDetailState();
}

class _SubscriptionChapterDetailState
    extends ConsumerState<_SubscriptionChapterDetail> {
  // Chapter 3 (lessons) starts expanded, others collapsed
  bool _infoExpanded = false;
  bool _paymentExpanded = false;
  bool _lessonsExpanded = true;

  Subscription get subscription => widget.subscription;
  bool get _isTeacher => widget.viewerRole == 'teacher';

  @override
  Widget build(BuildContext context) {
    final membershipAsync = ref.watch(membershipProvider(subscription.membershipId));

    return membershipAsync.when(
      data: (membership) {
        final instrument = membership?.instrument ?? AppStrings.instrumentFallback;
        final lessonClassAsync = membership != null
            ? ref.watch(lessonClassProvider(membership.lessonClassId))
            : null;

        return Scaffold(
          appBar: _buildAppBar(instrument, lessonClassAsync),
          bottomNavigationBar: SubscriptionActionBox(
            subscription: subscription,
            viewerRole: widget.viewerRole,
            onReschedule: () => _handleReschedule(context),
            onCancel: _isTeacher ? null : () => _handleCancel(context),
            onLessonComplete: _isTeacher ? () => _handleLessonComplete(context) : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Summary header
                _buildSummaryHeader(instrument),

                // Chapter 1: 수강권 정보
                ChapterSummary(
                  icon: Icons.confirmation_number_outlined,
                  title: AppStrings.chapterSubscriptionInfo,
                  completedDate: subscription.startDate != null
                      ? formatDateMD(subscription.startDate!)
                      : null,
                  summary: _infoSummary,
                  isExpanded: _infoExpanded,
                  isActive: false,
                  onTap: () => setState(() => _infoExpanded = !_infoExpanded),
                  child: SubscriptionChapterInfo(subscription: subscription),
                ),

                // Chapter 2: 결제 내역
                ChapterSummary(
                  icon: Icons.payment,
                  title: AppStrings.chapterPaymentHistory,
                  completedDate: subscription.paidAt != null
                      ? formatDateMD(subscription.paidAt!)
                      : null,
                  summary: _paymentSummary,
                  isExpanded: _paymentExpanded,
                  isActive: false,
                  onTap: () => setState(() => _paymentExpanded = !_paymentExpanded),
                  child: SubscriptionChapterPayment(subscription: subscription),
                ),

                // Chapter 3: 레슨 진행 (primary — expanded by default)
                ChapterSummary(
                  icon: Icons.music_note,
                  title: AppStrings.chapterLessonProgress(subscription.usedLessons, subscription.totalLessonsForDisplay ?? 0),
                  isExpanded: _lessonsExpanded,
                  isActive: true,
                  onTap: () => setState(() => _lessonsExpanded = !_lessonsExpanded),
                  child: SubscriptionChapterLessons(subscription: subscription),
                ),

                // Bottom divider
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.borderLight,
                ),

                // Bottom safe area padding
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppStrings.subscriptionDetailTitle), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(AppStrings.subscriptionDetailTitle), centerTitle: true),
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

  AppBar _buildAppBar(String instrument, AsyncValue<LessonClass?>? lessonClassAsync) {
    final className = lessonClassAsync?.valueOrNull?.name;
    final title = className != null ? '$instrument · $className' : instrument;

    return AppBar(
      title: Text(title),
      centerTitle: true,
    );
  }

  Widget _buildSummaryHeader(String instrument) {
    final colors = InstrumentColors.getColor(instrument);
    final statusColor = SubscriptionStatusColors.getColor(subscription);
    final remaining = subscription.remainingLessons ?? 0;
    final total = subscription.totalLessonsForDisplay ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.background,
      ),
      child: Column(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              SubscriptionStatusColors.getLabel(subscription),
              style: AppTypography.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Big remaining count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$remaining',
                style: AppTypography.displayLarge.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              Text(
                ' / $total회',
                style: AppTypography.headingMedium.copyWith(
                  color: colors.accent.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space1),

          // Progress bar
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? (total - remaining) / total : 0,
                minHeight: 8,
                backgroundColor: colors.accent.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Reschedule credits badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              '${AppStrings.rescheduleLabel} ${AppStrings.rescheduleCount(subscription.remainingReschedule, subscription.totalRescheduleAllowance)}',
              style: AppTypography.caption.copyWith(
                color: subscription.canReschedule
                    ? colors.accent
                    : AppColors.textTertiaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReschedule(BuildContext context) async {
    // Use a placeholder lesson time for now (next scheduled lesson)
    // In production, this would come from the actual scheduled lesson data
    final nextLessonTime = DateTime.now().add(const Duration(days: 3, hours: 14));

    final result = await showRescheduleBottomSheet(
      context,
      subscription: subscription,
      currentLessonDateTime: nextLessonTime,
      sessionNumber: subscription.usedLessons + 1,
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
    final nextLessonTime = DateTime.now().add(const Duration(days: 3, hours: 14));

    final result = await showCancelLessonBottomSheet(
      context,
      subscription: subscription,
      lessonDateTime: nextLessonTime,
      sessionNumber: subscription.usedLessons + 1,
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
            subscription.usedLessons + 1,
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

  String get _infoSummary {
    final parts = <String>[
      subscription.typeLabel,
      '${NumberFormat('#,###').format(subscription.amount)}${AppStrings.wonUnit}',
    ];
    if (subscription.endDate != null) {
      parts.add('~${formatDateMD(subscription.endDate!)}');
    }
    return parts.join(' · ');
  }

  String get _paymentSummary {
    final parts = <String>[
      subscription.paymentConfirmed ? AppStrings.paymentCompleted : AppStrings.paymentPending,
    ];
    if (subscription.paymentMethod != null) {
      parts.add(subscription.paymentMethod!.label);
    }
    return parts.join(' · ');
  }
}
