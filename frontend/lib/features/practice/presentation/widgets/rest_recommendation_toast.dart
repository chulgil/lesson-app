import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/rest_recommendation_policy.dart';

/// 휴식 권고 토스트 위젯.
///
/// 스펙 §9.4 / 플랜 Job 8 Task 8.2 / AC-7. RestRecommendationPolicy.evaluate()
/// 결과가 shouldShow=true 일 때 호출자가 띄움 (showModalBottomSheet 또는
/// ScaffoldMessenger 의존성 0 — 위젯 자체는 순수 build).
///
/// 강제 X — "계속하기" dismiss 1회 tap 으로 닫힘. 푸시 X (스펙 §2 SC-6 일관).
class RestRecommendationToast extends StatelessWidget {
  const RestRecommendationToast({
    super.key,
    required this.kind,
    required this.onDismiss,
  });

  final RestRecommendationKind kind;
  final VoidCallback onDismiss;

  String _resolveMessage() {
    switch (kind) {
      case RestRecommendationKind.session30:
        return AppStrings.restRecommendationSessionMessage;
      case RestRecommendationKind.daily180:
        return AppStrings.restRecommendationDailyMessage;
      case RestRecommendationKind.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _resolveMessage();
    return Container(
      key: const ValueKey('rest_recommendation_toast'),
      padding: EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(
            color: AppColors.inkQuaternary,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            ),
          ),
          SizedBox(width: AppSpacing.space4),
          GestureDetector(
            key: const ValueKey('rest_recommendation_dismiss'),
            onTap: onDismiss,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              child: Text(
                AppStrings.restRecommendationDismissLabel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
