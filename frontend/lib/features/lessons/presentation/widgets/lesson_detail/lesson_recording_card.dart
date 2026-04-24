// Lesson recording card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Recording card for lesson recordings
class LessonRecordingCard extends StatelessWidget {
  final String title;
  final String duration;
  final String date;
  final bool hasTranscript;
  final VoidCallback? onPlay;
  final VoidCallback? onViewTranscript;

  const LessonRecordingCard({
    super.key,
    required this.title,
    required this.duration,
    required this.date,
    this.hasTranscript = false,
    this.onPlay,
    this.onViewTranscript,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.audio_file, color: AppColors.paperAccent),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$date · $duration',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_circle_filled),
                iconSize: 40,
                color: AppColors.paperAccent,
              ),
            ],
          ),
          if (hasTranscript) ...[
            const SizedBox(height: AppSpacing.space3),
            GestureDetector(
              onTap: onViewTranscript,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(color: AppColors.paperDark),
                child: Row(
                  children: [
                    Icon(
                      Icons.text_snippet_outlined,
                      size: 16,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '텍스트 변환 완료',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '보기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
