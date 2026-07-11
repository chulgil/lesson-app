import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// 학생 홈 [연습 시작] 단일 진입점 카드.
///
/// 스펙 §4.1 / 플랜 Job 5 Task 5.1. Fitts' Law — 큰 [연습 시작] 버튼이
/// 카드 하단 thumb-zone 에 배치. 외부 데이터 의존 없이 props 만 받음.
class PracticeStartCard extends StatelessWidget {
  final String studentName;
  final int streakDays;
  final int yesterdayMinutes;
  final VoidCallback onStartTap;
  final VoidCallback? onMoreTap;
  final String? continuePieceName;
  final VoidCallback? onContinueTap;

  const PracticeStartCard({
    super.key,
    required this.studentName,
    required this.streakDays,
    required this.yesterdayMinutes,
    required this.onStartTap,
    this.onMoreTap,
    this.continuePieceName,
    this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              key: const ValueKey('practice_start_card_header'),
              AppStrings.practiceStartHeader(studentName),
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, size: 16),
                const SizedBox(width: 2),
                Text(
                  key: const ValueKey('practice_start_card_streak'),
                  AppStrings.practiceStartStreak(streakDays),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                key: const ValueKey('practice_start_button'),
                onPressed: onStartTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 18),
                    const SizedBox(width: 4),
                    const Text(AppStrings.practiceStartButton),
                  ],
                ),
              ),
            ),
            if (continuePieceName != null && onContinueTap != null) ...[
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                key: const ValueKey('practice_start_continue'),
                onPressed: onContinueTap,
                child: Text(
                  AppStrings.practiceStartContinuePiece(continuePieceName!),
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            Text(
              key: const ValueKey('practice_start_card_yesterday'),
              AppStrings.practiceStartYesterdayMinutes(yesterdayMinutes),
              style: AppTypography.bodySmall,
            ),
            if (onMoreTap != null) ...[
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                key: const ValueKey('practice_start_card_more'),
                onPressed: onMoreTap,
                child: const Text('· · ·', style: AppTypography.captionSmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
