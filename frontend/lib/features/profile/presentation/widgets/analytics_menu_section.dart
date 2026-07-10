// #1164 — 프로필 탭 통계·분석 섹션.
//
// TeacherAttendanceScreen (라우트만 등록, 네비게이션 0건) 진입점을 복원한다.
// 프로필 탭의 5묶음 카테고리 메뉴 행과 동일한 스타일(paperDark + InkWell +
// 아이콘 + 제목 + chevron)로 구성해 시각 일관성을 유지한다.
//
// Notebook 아이콘 정책: ProfileTab 메뉴 행은 시스템 affordance 컨벤션(Material)
// 우선 — CategoryCard 와 동일 예외.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 프로필 탭 통계·분석 섹션 — 섹션 헤더 + 출석 현황 진입 메뉴 행.
///
/// 진입 라우트는 ProfileTab 이 [onAttendanceTap] 콜백으로 주입한다
/// (CategoryMenuGrid 와 동일한 콜백 위임 패턴).
class AnalyticsMenuSection extends StatelessWidget {
  /// 출석 현황 메뉴 탭 콜백 — TeacherAttendanceScreen 으로 이동.
  final VoidCallback onAttendanceTap;

  const AnalyticsMenuSection({required this.onAttendanceTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.profileAnalyticsSectionTitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          _AnalyticsMenuRow(
            title: AppStrings.attendanceTitle,
            icon: Icons.fact_check_outlined,
            onTap: onAttendanceTap,
          ),
        ],
      ),
    );
  }
}

/// 통계·분석 섹션의 단일 메뉴 행 — CategoryCard 레이아웃과 동일(상태 라벨 제외).
class _AnalyticsMenuRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AnalyticsMenuRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperDark,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppSpacing.iconMD, color: AppColors.ink),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: AppSpacing.iconSM,
                color: AppColors.inkTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
