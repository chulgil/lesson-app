import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/daily_practice.dart';
import '../../domain/entities/gamification.dart';
import '../providers/growth_heatmap_provider.dart';
import '../widgets/heatmap_day_detail_sheet.dart';
import '../widgets/trophy_collection_card.dart';
import '../widgets/year_heatmap_grid.dart';

/// 학생 성장 디테일 화면 — 점점점 (…) 진입점.
///
/// 스펙 §4.4 / 플랜 Job 9 Task 9.1 / AC-6.4. 1년 히트맵 + 트로피 모음 +
/// P3/P4 placeholder. 14세 미만 → 비교 보기 placeholder hide (스펙 §9.1).
class StudentGrowthDetailScreen extends ConsumerWidget {
  const StudentGrowthDetailScreen({
    super.key,
    required this.studentId,
    this.earnedBadges = const [],
    this.isUnder14 = false,
  });

  final String studentId;
  final List<PracticeBadge> earnedBadges;
  final bool isUnder14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(growthHeatmapProvider(studentId));

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.growthDetailScreenTitle,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1년 히트맵
            Text(
              AppStrings.growthDetailYearLabel,
              style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
            ),
            SizedBox(height: AppSpacing.space3),
            heatmapAsync.when(
              data: (heatmap) => YearHeatmapGrid(
                heatmap: heatmap,
                asOf: DateTime.now().toUtc(),
                onDayTap: (date) {
                  final daily = heatmap.days[date];
                  showNotebookBottomSheet<void>(
                    context: context,
                    builder: (_) => HeatmapDayDetailSheet(
                      date: date,
                      daily: daily ?? const DailyPractice(),
                    ),
                  );
                },
              ),
              loading: () => const _LoadingPlaceholder(),
              // #74 무음 실패(SizedBox.shrink) → 보이는 에러 상태
              error: (_, __) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                child: Text(
                  AppStrings.errorOccurred,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.space5),

            // 트로피 모음
            TrophyCollectionCard(badges: earnedBadges),
            SizedBox(height: AppSpacing.space5),

            // Spotlight placeholder (P3)
            const _SpotlightPlaceholder(),
            SizedBox(height: AppSpacing.space5),

            // Comparison placeholder (P4) — 14세 미만 hide (§9.1)
            if (!isUnder14) const _ComparisonPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPlaceholder extends StatelessWidget {
  const _SpotlightPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('spotlight_placeholder'),
      padding: EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: Text(
        AppStrings.growthDetailSpotlightPlaceholder,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}

class _ComparisonPlaceholder extends StatelessWidget {
  const _ComparisonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('comparison_placeholder'),
      padding: EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: Text(
        AppStrings.growthDetailComparisonPlaceholder,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7 * 14.0,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.paperAccent,
          ),
        ),
      ),
    );
  }
}
