import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/availability_slot.dart';

/// Suggestion widget when no slots are available for selected date
///
/// Shows alternative dates with available slots.
class EmptySlotsSuggestion extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateSuggestion> suggestions;
  final ValueChanged<DateTime> onDateSelected;

  const EmptySlotsSuggestion({
    super.key,
    required this.selectedDate,
    required this.suggestions,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Empty state icon
        Text('😢', style: AppTypography.displayLarge.copyWith(fontSize: 48)),

        const SizedBox(height: AppSpacing.space3),

        // Message
        Text(
          '이 날은 예약 가능한 시간이\n없습니다',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.inkSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),

          // Divider
          const ThinRule(),

          const SizedBox(height: AppSpacing.space4),

          // Suggestions header
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '가장 가까운 예약 가능일',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Suggestion cards
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: _SuggestionCard(
                suggestion: suggestion,
                onSelect: () => onDateSelected(suggestion.date),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Data class for date suggestion
class DateSuggestion {
  final DateTime date;
  final List<AvailabilitySlot> availableSlots;

  const DateSuggestion({required this.date, required this.availableSlots});

  /// Get formatted date string (e.g., "2/20(목)")
  String get formattedDate {
    const weekdays = AppStrings.dayNamesShort;
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }

  /// Get preview of available times (max 3)
  String get timesPreview {
    if (availableSlots.isEmpty) return '';

    final times =
        availableSlots
            .where((s) => s.status == AvailabilitySlotStatus.available)
            .take(3)
            .map((s) => s.formattedStartTime)
            .toList();

    if (times.isEmpty) return '';

    final preview = times.join(', ');
    if (availableSlots.length > 3) {
      return '$preview 외 ${availableSlots.length - 3}개';
    }
    return preview;
  }
}

class _SuggestionCard extends StatelessWidget {
  final DateSuggestion suggestion;
  final VoidCallback onSelect;

  const _SuggestionCard({required this.suggestion, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              children: [
                // Date info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.formattedDate,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestion.timesPreview,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Select button
                TextButton(
                  onPressed: onSelect,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space2,
                    ),
                  ),
                  child: const Text(AppStrings.scheduleSelect),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
