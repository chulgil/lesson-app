import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../providers/practice_item_providers.dart';

/// 선생님 홈 [피드백 대기] 배지 카드 — 껍데기 감사 #415 / #1128.
///
/// 학생이 완료했으나 아직 선생님 리액션이 없는 과제 수를 노출한다. 0건이면
/// 노출되지 않는다(빈 카드 금지). 탭 시 [AwaitingFeedbackScreen] 진입.
/// [InvitePendingCard] 와 동일한 Notebook 카드 스타일 (paperDark + ink 테두리,
/// BoxShadow 없음, 각진 모서리).
class AwaitingFeedbackCard extends ConsumerWidget {
  const AwaitingFeedbackCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(awaitingFeedbackProvider).valueOrNull?.length ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: InkWell(
        onTap: () => context.push(AppRoutes.awaitingFeedback),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.awaitingFeedbackTitle,
                      style: NotebookTypography.eyebrow.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      AppStrings.awaitingFeedbackBadge(count),
                      style: NotebookTypography.sectionTitle.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
