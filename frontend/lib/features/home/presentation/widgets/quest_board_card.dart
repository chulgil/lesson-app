import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../providers/home_lesson_summary_provider.dart';
import '../providers/teacher_profile_completion_provider.dart';

// ignore: widget-smoke-test
// Smoke test deferred: ConsumerWidget requires live Riverpod container;
// covered by integration tests for DashboardTab.

/// Quest Board — profile completion gamification widget.
///
/// Replaces the old Getting Started checklist with a quest-style board
/// that shows a completion gauge and per-quest unlock rewards.
class QuestBoardCard extends ConsumerWidget {
  const QuestBoardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = ref.watch(profileCompletionPercentProvider);
    final hasSlots = ref.watch(hasAvailableSlotsProvider);
    final studentsAsync = ref.watch(homeStudentsProvider);
    final hasStudents = studentsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasPhoto = ref.watch(hasProfileImageProvider);
    final hasIntro = ref.watch(hasIntroductionProvider);
    final hasPrice = ref.watch(hasPriceTableProvider);
    final isPhoneVerified = ref.watch(homeTeacherPhoneVerifiedProvider);

    final allDone =
        hasSlots &&
        hasStudents &&
        hasPhoto &&
        hasIntro &&
        hasPrice &&
        isPhoneVerified;

    if (allDone) return const SizedBox.shrink();

    final quests = _buildQuests(
      context: context,
      hasSlots: hasSlots,
      hasStudents: hasStudents,
      hasPhoto: hasPhoto,
      hasIntro: hasIntro,
      hasPrice: hasPrice,
      isPhoneVerified: isPhoneVerified,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: QUEST BOARD + progress gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: NotebookSectionHeader(
                  label: AppStrings.questBoardTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              _ProgressGauge(percent: percent),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.questBoardIntro,
            style: NotebookTypography.hand.copyWith(
              fontSize: 14,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          for (int i = 0; i < quests.length; i++) ...[
            _QuestItem(quest: quests[i], index: i),
            if (i < quests.length - 1)
              const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ),
    );
  }

  List<_Quest> _buildQuests({
    required BuildContext context,
    required bool hasSlots,
    required bool hasStudents,
    required bool hasPhoto,
    required bool hasIntro,
    required bool hasPrice,
    required bool isPhoneVerified,
  }) {
    // Quest order designed by UX priority:
    // 1. Lesson time settings — students can't book without this
    // 2. Profile photo — builds trust, enables search visibility
    // 3. Introduction — unlocks web profile sharing
    // 4. Phone verification — earns "verified" badge
    // 5. Lesson price — shows pricing to students
    // 6. First student invite — LAST, requires all setup complete first
    return [
      _Quest(
        step: 1,
        title: AppStrings.questTitleSlots,
        reward: AppStrings.questRewardSlots,
        isCompleted: hasSlots,
        onTap: () => context.push(AppRoutes.lessonTimeSettings),
      ),
      _Quest(
        step: 2,
        title: AppStrings.questTitlePhoto,
        reward: AppStrings.questRewardSearch,
        isCompleted: hasPhoto,
        onTap: () => context.push(AppRoutes.basicInfoEdit),
      ),
      _Quest(
        step: 3,
        title: AppStrings.questTitleIntro,
        reward: AppStrings.questRewardWebProfile,
        isCompleted: hasIntro,
        onTap: () => context.push(AppRoutes.basicInfoEdit),
      ),
      _Quest(
        step: 4,
        title: AppStrings.questTitlePhone,
        reward: AppStrings.questRewardVerified,
        isCompleted: isPhoneVerified,
        onTap:
            isPhoneVerified
                ? null
                : () => context.push(AppRoutes.teacherPhoneVerification),
      ),
      _Quest(
        step: 5,
        title: AppStrings.questTitlePrice,
        reward: AppStrings.questRewardPrice,
        isCompleted: hasPrice,
        onTap: null,
      ),
      _Quest(
        step: 6,
        title: AppStrings.questTitleStudent,
        reward: AppStrings.questRewardConnection,
        isCompleted: hasStudents,
        onTap: () => context.push(AppRoutes.invite),
      ),
    ];
  }
}

// ── Internal data model ───────────────────────────────────────────────────────

class _Quest {
  final int step;
  final String title;
  final String? reward;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _Quest({
    required this.step,
    required this.title,
    required this.reward,
    required this.isCompleted,
    required this.onTap,
  });
}

// ── Progress gauge ────────────────────────────────────────────────────────────

class _ProgressGauge extends StatelessWidget {
  final int percent;

  const _ProgressGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    const gaugeWidth = 80.0;
    const gaugeHeight = 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: gaugeWidth,
          height: gaugeHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.inkQuaternary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '$percent%',
          style: NotebookTypography.roman.copyWith(
            color: AppColors.inkSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Quest item row ─────────────────────────────────────────────────────────────

class _QuestItem extends StatelessWidget {
  final _Quest quest;
  final int index;

  const _QuestItem({required this.quest, required this.index});

  @override
  Widget build(BuildContext context) {
    final isEnabled = quest.onTap != null;
    final accentColor =
        quest.isCompleted
            ? AppColors.paperOk
            : isEnabled
            ? AppColors.ink
            : AppColors.inkTertiary;

    return Opacity(
      opacity: !quest.isCompleted && !isEnabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: quest.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roman numeral or check glyph
              SizedBox(
                width: 28,
                child:
                    quest.isCompleted
                        ? const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: NotebookGlyph(
                            NotebookGlyph.check,
                            size: 16,
                            color: AppColors.paperOk,
                          ),
                        )
                        : Text(
                          romanOf(quest.step - 1),
                          style: NotebookTypography.roman.copyWith(
                            color: accentColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: NotebookTypography.pieceTitle.copyWith(
                        fontSize: 15,
                        color:
                            quest.isCompleted
                                ? AppColors.inkTertiary
                                : AppColors.ink,
                        decoration:
                            quest.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                    if (quest.reward != null && !quest.isCompleted) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          NotebookGlyph(
                            NotebookGlyph.arrowRight,
                            size: 12,
                            color: AppColors.inkTertiary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              quest.reward!,
                              style: NotebookTypography.roman.copyWith(
                                fontSize: 12,
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isEnabled && !quest.isCompleted)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.ink,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
