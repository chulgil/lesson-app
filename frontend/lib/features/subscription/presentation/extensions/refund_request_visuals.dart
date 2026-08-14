import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/refund_request.dart';

/// Presentation-layer display mapping for refund requests (#1271).
///
/// Keeps the domain entity pure — labels/colors live here, not on the enum
/// (C2/C3 — no emoji getters, single SSOT for status→label/color).
extension RefundRequestStatusVisualX on RefundRequestStatus {
  String get label {
    switch (this) {
      case RefundRequestStatus.requested:
        return AppStrings.refundStatusRequested;
      case RefundRequestStatus.completed:
        return AppStrings.refundStatusCompleted;
      case RefundRequestStatus.rejected:
        return AppStrings.refundStatusRejected;
    }
  }

  /// 3색 잉크 팔레트 (SubscriptionStatusColors 와 동일 원칙): 대기=중립
  /// 회색, 완료=녹색 성공, 반려=버밀리온 부정적 결과.
  Color get color {
    switch (this) {
      case RefundRequestStatus.requested:
        return AppColors.inkTertiary;
      case RefundRequestStatus.completed:
        return AppColors.paperOk;
      case RefundRequestStatus.rejected:
        return AppColors.paperAccent;
    }
  }
}

extension RefundRequestVisualX on RefundRequest {
  String get statusLabel => status.label;
  Color get statusColor => status.color;
}
