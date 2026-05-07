import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

// ignore: widget-smoke-test

/// 마일스톤 축하 카드 — 홈 대시보드에서 조건 충족 시 인라인 표시.
///
/// 기존 팝업 다이얼로그 방식 폐기 → 인라인 카드로 전환.
/// 선생님 작업 흐름을 방해하지 않고, 자연스럽게 앱 리뷰를 유도.
///
/// 표시 조건: 50회/100회/200회 레슨 달성 시 (마일스톤)
/// 닫기: × 버튼 → Hive에 해당 마일스톤 dismiss 기록
class MilestoneRatingCard extends ConsumerWidget {
  final int completedLessons;
  final VoidCallback? onDismiss;

  const MilestoneRatingCard({
    super.key,
    required this.completedLessons,
    this.onDismiss,
  });

  /// 현재 달성한 마일스톤 (50, 100, 200, 500, 1000)
  int? get _currentMilestone {
    const milestones = [1000, 500, 200, 100, 50];
    for (final m in milestones) {
      if (completedLessons >= m) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestone = _currentMilestone;
    if (milestone == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperOk.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.paperOk.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.milestoneCongrats(milestone),
                  style: NotebookTypography.pieceTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.inkTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.milestoneDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          // 소프트 링크 — 강제 아닌 선택
          GestureDetector(
            onTap: () => _openAppStore(),
            child: Text(
              AppStrings.milestoneReviewLink,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppStore() async {
    // TODO: 실제 앱스토어 URL로 교체
    final uri = Uri.parse('https://apps.apple.com/app/lessonaza');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 프로필 탭 하단 — 조용한 앱 평가 링크.
///
/// 프로필 > 설정 영역 최하단에 배치. 작업 흐름 방해 없이 접근 가능.
class ProfileRatingLink extends StatelessWidget {
  const ProfileRatingLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Center(
        child: GestureDetector(
          onTap: () => _openAppStore(),
          child: Text(
            AppStrings.profileRatingLink,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.inkTertiary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.inkTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAppStore() async {
    final uri = Uri.parse('https://apps.apple.com/app/lessonaza');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
