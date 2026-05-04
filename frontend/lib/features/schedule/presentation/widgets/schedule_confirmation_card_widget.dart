import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../domain/entities/schedule_confirmation_card.dart';
import '../providers/schedule_confirmation_card_providers.dart';
import '../providers/teacher_availability_providers.dart';

/// Widget to display a schedule confirmation card to the student.
///
/// Shows after a subscription has been issued, prompting the student
/// to confirm their lesson schedule. Based on the scenario, it may
/// suggest a previous schedule or trial lesson time.
class ScheduleConfirmationCardWidget extends ConsumerWidget {
  final ScheduleConfirmationCard card;
  final VoidCallback? onConfirmed;
  final VoidCallback? onSelectDifferentTime;

  const ScheduleConfirmationCardWidget({
    super.key,
    required this.card,
    this.onConfirmed,
    this.onSelectDifferentTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifierState = ref.watch(scheduleConfirmationCardNotifierProvider);
    final isLoading = notifierState.isLoading;

    return NotebookCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.paperOk.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.paperOk.withValues(alpha: 0.05),
              AppColors.paperOk.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with celebration icon
              _buildHeader(context),
              const SizedBox(height: AppSpacing.space4),

              // Teacher and subscription info
              _buildSubscriptionInfo(context),
              const SizedBox(height: AppSpacing.space4),

              // Schedule suggestion section
              _buildScheduleSection(context),
              const SizedBox(height: AppSpacing.space4),

              // Action buttons
              _buildActionButtons(context, ref, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space2),
          decoration: BoxDecoration(
            color: AppColors.paperOk.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.celebration,
            color: AppColors.paperOk,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.subscriptionIssuedMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.paperOk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.subscriptionReadyScheduleNeeded,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo(BuildContext context) {
    final instrumentText =
        card.instrument != null ? ' · ${card.instrument}' : '';
    final lessonsText =
        card.totalLessons != null ? ' ${card.totalLessons}회권' : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.paperAccentSoft,
            child: Text(
              card.teacherName.isNotEmpty ? card.teacherName[0] : '?',
              style: TextStyle(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.teacherName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$instrumentText$lessonsText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    // Different UI based on card type
    if (!card.hasSuggestedSchedule) {
      return _buildNoSuggestionSection(context);
    }

    final options = card.formattedOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 18, color: AppColors.inkSecondary),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                card.hasMultipleOptions
                    ? '원하시는 시간을 선택해주세요'
                    : card.cardType.suggestionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Show all available options
        for (int i = 0; i < options.length; i++) ...[
          _buildScheduleOption(
            context,
            label: options[i],
            isRecommended: i == 0,
            optionIndex: i,
          ),
          if (i < options.length - 1) const SizedBox(height: AppSpacing.space2),
        ],
      ],
    );
  }

  Widget _buildScheduleOption(
    BuildContext context, {
    required String label,
    required bool isRecommended,
    required int optionIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: isRecommended ? AppColors.paperAccentSoft : AppColors.paper,
        border: Border.all(
          color:
              isRecommended ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
      child: Row(
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: Icon(Icons.star, color: AppColors.paperAccent, size: 16),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: AppColors.inkTertiary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.access_time,
                color: AppColors.inkSecondary,
                size: 16,
              ),
            ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecommended)
                  Text(
                    _getScheduleTypeLabel(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isRecommended ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuggestionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, color: AppColors.ink, size: 32),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '레슨 시간을 선택해주세요',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '선생님의 가용 시간 중에서 원하는 시간을 선택할 수 있습니다',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
          ),
        ],
      ),
    );
  }

  String _getScheduleTypeLabel() {
    switch (card.cardType) {
      case ScheduleCardType.afterTrial:
        return '체험 레슨 시간';
      case ScheduleCardType.reEnrollment:
        return '이전 스케줄';
      case ScheduleCardType.additionalInstrument:
        return '';
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    if (!card.hasSuggestedSchedule) {
      // Only "Select Time" button for additionalInstrument
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              isLoading ? null : () => _onSelectDifferentTime(context, ref),
          icon: const Icon(Icons.access_time, size: 18),
          label: const Text(AppStrings.scheduleSelectTime),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
            shape: RoundedRectangleBorder(),
          ),
        ),
      );
    }

    // Two buttons: Confirm and Select Different Time
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                isLoading ? null : () => _onSelectDifferentTime(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.inkSecondary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.inkQuaternary),
              shape: RoundedRectangleBorder(),
            ),
            child: const Text(AppStrings.scheduleDifferentTime),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _onConfirm(context, ref),
            icon:
                isLoading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.paper,
                      ),
                    )
                    : const Icon(Icons.check, size: 18),
            label: const Text(AppStrings.scheduleBookThisTime),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperOk,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              shape: RoundedRectangleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(scheduleConfirmationCardNotifierProvider.notifier)
          .confirmSchedule(card.id, card.studentId);

      // Book the lesson with the suggested schedule
      if (card.hasSuggestedSchedule) {
        final nextLessonDate = _getNextDateForDay(card.suggestedDay!);
        final timeParts = card.suggestedTime!.split(':');
        final startHour = int.parse(timeParts[0]);
        final startMinute = int.parse(timeParts[1]);
        final duration = card.lessonDuration ?? 50;
        final endMinute = startMinute + duration;
        final endHour = startHour + endMinute ~/ 60;
        final endMin = endMinute % 60;

        final slotId =
            'confirmed_${card.id}_${DateTime.now().millisecondsSinceEpoch}';

        await ref
            .read(slotBookingNotifierProvider.notifier)
            .bookSlot(
              slotId,
              card.studentId,
              card.teacherName,
              teacherId: card.teacherId,
              teacherName: card.teacherName,
              slotDate: nextLessonDate,
              slotStartTime: TimeOfDay(hour: startHour, minute: startMinute),
              slotEndTime: TimeOfDay(hour: endHour, minute: endMin),
              instrument: card.instrument,
              lessonType: LessonType.regular,
            );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.formattedSuggestedSchedule} 스케줄이 확정되었습니다!'),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }

      onConfirmed?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.scheduleConfirmError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  /// Get the next occurrence of the given weekday (1=Mon, 7=Sun).
  DateTime _getNextDateForDay(int day) {
    final now = DateTime.now();
    // DateTime.weekday: 1=Mon, 7=Sun (matches our format)
    final daysUntil = (day - now.weekday + 7) % 7;
    // If today is the target day, schedule for next week
    final offset = daysUntil == 0 ? 7 : daysUntil;
    return DateTime(now.year, now.month, now.day + offset);
  }

  void _onSelectDifferentTime(BuildContext context, WidgetRef ref) {
    // Navigate to booking screen to select a different time
    context.push(
      '${AppRoutes.lessonBooking}'
      '?teacherId=${card.teacherId}'
      '&teacherName=${Uri.encodeComponent(card.teacherName)}'
      '&studentId=${card.studentId}'
      '&instrument=${Uri.encodeComponent(card.instrument ?? '')}'
      '&subscriptionId=${card.subscriptionId}',
    );

    // Mark card as "changed time" after navigation
    ref
        .read(scheduleConfirmationCardNotifierProvider.notifier)
        .selectDifferentTime(card.id, card.studentId);

    onSelectDifferentTime?.call();
  }
}
