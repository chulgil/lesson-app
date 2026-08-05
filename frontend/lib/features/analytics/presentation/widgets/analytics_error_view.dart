import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared error state for sibling analytics tabs (C7 — 형제 탭 에러 정책 단일화).
///
/// Replaces the per-tab inline error `Center`s so revenue / student-growth /
/// summary tabs share one error affordance: error icon + "불러올 수 없습니다" +
/// 재시도 버튼.
class AnalyticsErrorView extends StatelessWidget {
  const AnalyticsErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(AppStrings.cannotLoadData, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space3),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
