import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../domain/entities/child_profile.dart';
import '../../../../features/parent_home/parent_home_facade.dart';
import '../extensions/parent_home_domain_visuals.dart';
import '../widgets/profile_switcher.dart';

/// Dashboard for unconnected children (practice/metronome only)
///
/// Features available:
/// - Practice recording (time-based)
/// - Metronome
///
/// Features NOT available:
/// - Repertoire (requires teacher)
/// - Lesson scheduling (requires teacher)
/// - Assignments (requires teacher)
class UnconnectedChildDashboard extends ConsumerWidget {
  const UnconnectedChildDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChild = ref.watch(activeChildProfileProvider);

    if (activeChild == null) {
      return const NotebookScreenScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DebugWrapper(
      child: NotebookScreenScaffold(
        backgroundColor: AppColors.paperDark,
        appBar: AppBar(
          backgroundColor: AppColors.paperDark,
          elevation: 0,
          title: const ProfileSwitcher(),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChildHeader(activeChild),
                const SizedBox(height: AppSpacing.space6),
                // #78 "연습 기록" 카드는 NO-OP(스낵바만, 미구현 화면) 이라 제거.
                _buildTeacherConnectionBanner(context),
                const SizedBox(height: AppSpacing.space6),
                _buildPracticeHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildHeader(ChildProfile child) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: child.profileColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.zero,
          ),
          child: Center(
            child: Text(
              child.initial,
              style: AppTypography.headingLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: child.profileColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    child.name,
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: child.connectionStatus.color.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          child.connectionStatus.icon,
                          size: 12,
                          color: child.connectionStatus.color,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          child.connectionStatus.label,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: child.connectionStatus.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '${child.instrumentLabel} · ${child.levelLabel}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherConnectionBanner(BuildContext context) {
    // §7.132: paperAccent.alpha 변형(gradient·border) → paperAccentSoft + paperAccent solid border.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // §7.132: paperAccent.alpha → paperAccentSoft.
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: AppColors.paperAccentSoft,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.paperAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notebook × Score: 연결 유도 카드 제목은 Playfair sectionTitle
                    // 로 통일 (§7.17).
                    Text(
                      AppStrings.parentHomeConnectTeacherCta,
                      style: NotebookTypography.sectionTitle.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.parentHomeConnectBenefits,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFindTeacherDialog(context),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(AppStrings.parentHomeFindTeacher),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    side: const BorderSide(color: AppColors.paperAccent),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _enterInviteCode(context),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text(AppStrings.parentHomeInviteCode),
                  // §7.132: foregroundColor white → paper.
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 정적 섹션 헤더 (§7.17) — Playfair sectionTitle.
        // #78 "전체 보기" NO-OP(TODO) 버튼 제거.
        Text(
          AppStrings.parentHomeWeeklyPractice,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildWeeklyPracticeGrid(),
      ],
    );
  }

  Widget _buildWeeklyPracticeGrid() {
    // Get the current week dates
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = AppStrings.dayNamesShort;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final isToday =
            date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
        final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

        // TODO: Replace with actual practice data from repository
        // Using index-based stub to avoid dead_code warning until data is connected
        final hasPractice = index < 0; // Will be: practiceData[date] != null

        return Column(
          children: [
            Text(
              weekDays[index],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.paperAccent
                    : hasPractice
                    ? AppColors.paperOkSoft
                    : isPast
                    ? AppColors.paperDark
                    : Colors.transparent,
                borderRadius: BorderRadius.zero,
                border: isToday
                    ? null
                    : Border.all(
                        color: hasPractice
                            ? AppColors.paperOk
                            : AppColors.inkQuaternary,
                        width: hasPractice ? 2 : 1,
                      ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? AppColors.paper
                        : hasPractice
                        ? AppColors.paperOk
                        : AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFindTeacherDialog(BuildContext context) {
    // TODO: Navigate to teacher search
    context.push(AppRoutes.teacherSearch);
  }

  void _enterInviteCode(BuildContext context) {
    // #78 NO-OP 인라인 다이얼로그(코드 미처리) 제거 → 실제 학부모 초대코드 화면으로.
    context.push(AppRoutes.parentInviteCode);
  }
}
