import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';

/// Card showing active challenges for a student.
/// Used in the badge collection screen and student dashboard.
class ChallengesCard extends ConsumerWidget {
  const ChallengesCard({
    super.key,
    required this.studentId,
    this.maxVisible = 3,
    this.onViewAll,
  });

  final String studentId;
  final int maxVisible;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider(studentId));

    return challengesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (challenges) {
        if (challenges.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.local_fire_department_outlined,
            title: AppStrings.gamificationChallengesComingSoon,
            subtitle: AppStrings.gamificationChallengesComingSoonSubtitle,
          );
        }

        final visible = challenges.take(maxVisible).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🏆', style: AppTypography.headingMedium),
                  const SizedBox(width: AppSpacing.space2),
                  // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
                  Text(
                    AppStrings.gamificationChallenges,
                    style: NotebookTypography.sectionTitle,
                  ),
                  const Spacer(),
                  if (challenges.length > maxVisible && onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      child: Text(
                        '전체 보기',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              ...visible.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: _ChallengeItem(challenge: c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  const _ChallengeItem({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.type.icon, style: AppTypography.bodyLarge),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  challenge.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: challenge.period == ChallengePeriod.weekly
                      ? AppColors.ink.withValues(alpha: 0.1)
                      : AppColors.paperAccentSoft,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  challenge.period.displayName,
                  style: AppTypography.caption.copyWith(
                    color: challenge.period == ChallengePeriod.weekly
                        ? AppColors.ink
                        : AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    backgroundColor: AppColors.inkQuaternary,
                    valueColor: AlwaysStoppedAnimation(
                      challenge.progress >= 1.0
                          ? AppColors.paperOk
                          : AppColors.paperAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '${challenge.currentValue}/${challenge.targetDisplay}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              Text(
                '${challenge.rewardPoints}P 보상',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'D-${challenge.remainingDays}',
                style: AppTypography.caption.copyWith(
                  color: challenge.remainingDays <= 2
                      ? AppColors.paperAccent
                      : AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
