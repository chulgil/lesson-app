import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/error_state_widget.dart';

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
    return ErrorStateWidget(
      title: AppStrings.cannotLoadData,
      actionLabel: AppStrings.retry,
      onAction: onRetry,
    );
  }
}
