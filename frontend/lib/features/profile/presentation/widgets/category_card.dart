// W2 Task 2.3 — 5묶음 카테고리 카드 위젯.
// spec §7.2 5묶음 메뉴 영역 시안 + §11.1 상태 라벨 규칙.
//
// 사용처: ProfileTab (Task 2.4) — 운영시간/수업방식/수강권·정산/내 프로필/정책·알림.
//
// Notebook 아이콘 정책: `*_card.dart` 는 시그니처 영역이지만, ProfileTab 의 다른
// 카드와 일관성을 위해 Material `Icons.*` 를 허용한다 (notebook-icon 예외).

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../extensions/category_status_visuals.dart';
import '../providers/category_status_provider.dart';

// ignore: notebook-icon — ProfileTab 메뉴 카드는 시스템 affordance 컨벤션(Material) 우선.

/// 프로필 탭 5묶음 카테고리 카드.
///
/// 좌측 아이콘 + 제목 / 우측 상태 라벨 + (옵션) NEW 배지 / (옵션) 노란 점 / chevron.
///
/// 상태 라벨/색상/노란 점 표시는 [CategoryStatusVisuals] 가 결정.
class CategoryCard extends StatelessWidget {
  /// 카드 제목 (예: "운영시간").
  final String title;

  /// 좌측 아이콘.
  final IconData icon;

  /// 진행 상태 (provider 가 계산).
  final CategoryStatus status;

  /// 탭 콜백 — 해당 카테고리 화면으로 이동.
  final VoidCallback onTap;

  /// NEW 배지 표시 (W6 — 신규 메뉴 7일간).
  final bool showNewBadge;

  const CategoryCard({
    required this.title,
    required this.icon,
    required this.status,
    required this.onTap,
    this.showNewBadge = false,
    super.key,
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
              if (showNewBadge) ...[
                const _NewBadge(),
                const SizedBox(width: AppSpacing.space2),
              ],
              _StatusLabel(status: status),
              if (status.showWarningDot) ...[
                const SizedBox(width: AppSpacing.space2),
                const _WarningDot(),
              ],
              const SizedBox(width: AppSpacing.space1),
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

class _StatusLabel extends StatelessWidget {
  final CategoryStatus status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    return Text(
      status.label,
      style: AppTypography.bodySmall.copyWith(color: status.color),
    );
  }
}

/// 미설정 affordance — paperAccent 색 작은 원 (⚠ ●).
class _WarningDot extends StatelessWidget {
  const _WarningDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('category_card_dot_warning'),
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.paperAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// W6 신규 메뉴 NEW 배지.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('category_card_badge_new'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: const BoxDecoration(color: AppColors.paperAccent),
      child: Text(
        AppStrings.categoryNewBadge,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.paper,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
