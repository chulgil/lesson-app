import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/practice/domain/entities/practice_repertoire.dart';
import 'section_recording_list_item.dart';

/// Displays the recordings list section with recording items
/// and empty state placeholders. Always shows all recordings.
class SectionRecordingsSection extends StatelessWidget {
  final PracticeSection section;
  final String repertoireId;
  final List<PracticeRecording> recordings;
  final void Function(String recordingId) onSetRepresentative;
  final void Function(String recordingId) onDelete;
  final void Function(PracticeRecording recording) onPlay;

  const SectionRecordingsSection({
    super.key,
    required this.section,
    required this.repertoireId,
    required this.recordings,
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
        Text(
          '녹음 기록 (${recordings.length})',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Recordings list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recordings.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.space2),
          itemBuilder: (context, index) {
            final recording = recordings[index];
            return SectionRecordingListItem(
              recording: recording,
              sectionId: section.id,
              repertoireId: repertoireId,
              onSetRepresentative: () => onSetRepresentative(recording.id),
              onDelete: () => onDelete(recording.id),
              onPlay: () => onPlay(recording),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyRecordingsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '아직 녹음이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '위의 녹음 버튼을 눌러 연습을 기록해보세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

