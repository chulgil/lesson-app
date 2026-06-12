import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../profile/profile_facade.dart' show questCelebrationProvider;

/// 11/11 퀘스트 모두 완료 시 1회 표시되는 축하 카드 (§8.3).
///
/// 표시 조건은 [QuestBoardCard] 가 결정 (allMandatoryDone && !celebrated).
/// dismiss 시 [QuestCelebration.markCelebrated] 호출 → 재진입 시 미표시.
class QuestCelebrationCard extends ConsumerWidget {
  const QuestCelebrationCard({super.key, this.onDismissed});

  /// dismiss 직후 호출 (테스트/스크롤 위치 복원 등 부가 처리).
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const NotebookGlyph(
                  NotebookGlyph.starFilled,
                  size: 22,
                  color: AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.questCelebrationTitle,
                    style: NotebookTypography.pieceTitle.copyWith(
                      fontSize: 16,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.inkSecondary,
                  ),
                  tooltip: AppStrings.questCelebrationDismiss,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dismiss(ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.questCelebrationBody,
              style: NotebookTypography.handMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: _CelebrationActionButton(
                    label: AppStrings.questCelebrationActionLessons,
                    onPressed: () {
                      _dismiss(ref);
                      context.push(AppRoutes.lessons);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: _CelebrationActionButton(
                    label: AppStrings.questCelebrationActionStats,
                    // 주간 통계 라우트 미존재 → practiceStats 로 대체 (Issue #608 참조).
                    onPressed: () {
                      _dismiss(ref);
                      context.push(AppRoutes.practiceStats);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _dismiss(WidgetRef ref) {
    // ignore: discarded_futures — fire-and-forget, Hive write 는 best-effort.
    ref.read(questCelebrationProvider.notifier).markCelebrated();
    onDismissed?.call();
  }
}

class _CelebrationActionButton extends StatelessWidget {
  const _CelebrationActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        // 컴팩트 배치 — minimumSize 명시 (테마 minWidth=∞ × Row Expanded 크래시 방지).
        minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
        side: const BorderSide(color: AppColors.ink, width: 1.5),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: NotebookTypography.roman.copyWith(
          fontSize: 13,
          color: AppColors.ink,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
