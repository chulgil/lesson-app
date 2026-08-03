import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/daily_practice.dart';
import '../providers/daily_practice_goal_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/growth_heatmap_provider.dart';
import '../providers/streak_freeze_provider.dart';
import '../widgets/heatmap_day_detail_sheet.dart';
import '../widgets/trophy_collection_card.dart';
import '../widgets/year_heatmap_grid.dart';

/// 학생 성장 디테일 화면 — 점점점 (…) 진입점.
///
/// 스펙 §4.4 / 플랜 Job 9 Task 9.1 / AC-6.4. 1년 히트맵 + 트로피 모음.
class StudentGrowthDetailScreen extends ConsumerWidget {
  const StudentGrowthDetailScreen({
    super.key,
    required this.studentId,
  });

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(growthHeatmapProvider(studentId));
    // #936: earnedBadges 는 provider 에서 읽어야 트로피 그리드에 반영됨.
    // 라우터에서 직접 전달하지 않아도 studentGamificationProvider 가 최신 값을 공급.
    final gamificationAsync = ref.watch(studentGamificationProvider(studentId));
    final earnedBadges =
        gamificationAsync.valueOrNull?.earnedBadges ?? const [];
    // doc 46 §4 (데일리 만족 루프 P2) — 오늘의 목표 대비 잔디 강도 + freeze 로
    // 지킨 날짜 표시. 값이 없으면 YearHeatmapGrid 는 기존 정적 5단계로 폴백.
    final goalMinutes = ref
        .watch(dailyPracticeGoalProvider(studentId))
        .valueOrNull;
    final frozenDates = ref
        .watch(studentStreakFreezeProvider(studentId))
        .valueOrNull
        ?.usedAt
        .map((d) => DateTime.utc(d.year, d.month, d.day))
        .toSet();

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
              data:
                  (heatmap) => YearHeatmapGrid(
                    heatmap: heatmap,
                    asOf: DateTime.now().toUtc(),
                    goalMinutes: goalMinutes,
                    frozenDates: frozenDates,
                    onDayTap: (date) {
                      final daily = heatmap.days[date];
                      showNotebookBottomSheet<void>(
                        context: context,
                        builder:
                            (_) => HeatmapDayDetailSheet(
                              date: date,
                              daily: daily ?? const DailyPractice(),
                            ),
                      );
                    },
                  ),
              loading: () => const _LoadingPlaceholder(),
              // #74 무음 실패(SizedBox.shrink) → 보이는 에러 상태
              error:
                  (_, __) => Padding(
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
          ],
        ),
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
