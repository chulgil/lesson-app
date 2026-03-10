import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';
import '../../../domain/entities/recording_filter_type.dart';
import 'recording_filter_dropdown.dart';
import 'section_recording_list_item.dart';

/// Displays the recordings list section with filter dropdown,
/// recording items, and empty state placeholders.
class SectionRecordingsSection extends StatelessWidget {
  final PracticeSection section;
  final String repertoireId;
  final RecordingFilterType recordingFilter;
  final List<PracticeRecording> filteredRecordings;
  final ValueChanged<RecordingFilterType> onFilterChanged;
  final void Function(String recordingId) onSetRepresentative;
  final void Function(String recordingId) onDelete;
  final void Function(PracticeRecording recording) onPlay;

  const SectionRecordingsSection({
    super.key,
    required this.section,
    required this.repertoireId,
    required this.recordingFilter,
    required this.filteredRecordings,
    required this.onFilterChanged,
    required this.onSetRepresentative,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (section.recordings.isEmpty) {
      return _buildEmptyRecordingsPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '녹음 기록 (${filteredRecordings.length})',
              style: AppTypography.headingSmall,
            ),
            // Recording filter dropdown
            RecordingFilterDropdown(
              selectedFilter: recordingFilter,
              onFilterChanged: onFilterChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Recordings list or empty filter message
        if (filteredRecordings.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRecordings.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.space2),
            itemBuilder: (context, index) {
              final recording = filteredRecordings[index];
              return SectionRecordingListItem(
                recording: recording,
                sectionId: section.id,
                repertoireId: repertoireId,
                onSetRepresentative: () => onSetRepresentative(recording.id),
                onDelete: () => onDelete(recording.id),
                onPlay: () => onPlay(recording),
              );
            },
          )
        else
          // Empty filtered result (but recordings exist)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(
              '${recordingFilter.displayLabel} 녹음이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyRecordingsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '아직 녹음이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '위의 녹음 버튼을 눌러 연습을 기록해보세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filters recordings based on filter type and selected date.
///
/// Extracted as a standalone function so it can be reused and tested
/// independently of the screen widget.
List<PracticeRecording> filterRecordings({
  required List<PracticeRecording> recordings,
  required RecordingFilterType filter,
  required DateTime? selectedDate,
}) {
  final referenceDate = selectedDate ?? DateTime.now();

  switch (filter) {
    case RecordingFilterType.all:
      // Show all recordings up to selected date (if set)
      if (selectedDate != null) {
        final selectedDateOnly = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        return recordings.where((r) {
          final localCreatedAt = r.createdAt.toLocal();
          final recordingDate = DateTime(
            localCreatedAt.year,
            localCreatedAt.month,
            localCreatedAt.day,
          );
          return !recordingDate.isAfter(selectedDateOnly);
        }).toList();
      }
      return recordings;

    case RecordingFilterType.weekly:
      // Show recordings from the week containing the reference date (Mon-Sun)
      // Use local time for comparison
      final weekday = referenceDate.weekday; // 1=Mon, 7=Sun
      final monday = referenceDate.subtract(Duration(days: weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final weekStart = DateTime(monday.year, monday.month, monday.day);
      final weekEnd = DateTime(sunday.year, sunday.month, sunday.day);

      return recordings.where((r) {
        final localCreatedAt = r.createdAt.toLocal();
        final recordingDate = DateTime(
          localCreatedAt.year,
          localCreatedAt.month,
          localCreatedAt.day,
        );
        return !recordingDate.isBefore(weekStart) &&
            !recordingDate.isAfter(weekEnd);
      }).toList();

    case RecordingFilterType.daily:
      // Show recordings from the reference date only
      // Use local time for comparison to handle timezone issues
      final referenceDateOnly = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
      );
      return recordings.where((r) {
        final localCreatedAt = r.createdAt.toLocal();
        final recordingDateOnly = DateTime(
          localCreatedAt.year,
          localCreatedAt.month,
          localCreatedAt.day,
        );
        return recordingDateOnly == referenceDateOnly;
      }).toList();
  }
}
