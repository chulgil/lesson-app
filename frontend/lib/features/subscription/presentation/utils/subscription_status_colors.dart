import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/subscription.dart';

/// Common subscription status colors for consistent UI across all screens.
///
/// Notebook × Score 팔레트 (3색 원칙):
/// - paperOk (녹색 펜): 이용중 (건강한 활성)
/// - paperAccent (Vermillion Red): 갱신 필요 (warning+error 병합)
/// - inkTertiary (회색 연필): 만료됨, 일시정지
/// - paperHighlight (노란 형광펜): 사용 완료 (성취 표시)
class SubscriptionStatusColors {
  SubscriptionStatusColors._();

  /// Get the appropriate color based on subscription status.
  /// Priority: Depleted > Expired > ExpiringSoon > Paused > Active
  static Color getColor(Subscription subscription) {
    if (subscription.isDepleted) {
      return AppColors.paperHighlight; // 사용 완료 (노란 형광펜) - 성취
    }
    if (subscription.isExpired) {
      return AppColors.inkTertiary; // 만료됨 (회색)
    }
    if (subscription.isExpiringSoon) {
      return AppColors.paperAccent; // 갱신 필요 (Vermillion)
    }
    if (subscription.status == SubscriptionStatus.paused) {
      return AppColors.inkTertiary; // 일시정지 (회색)
    }
    return AppColors.paperOk; // 이용중 (녹색 펜)
  }

  /// Get the progress/accent color (for progress bars, indicators).
  static Color getProgressColor(Subscription subscription) {
    if (subscription.isDepleted) {
      return AppColors.paperHighlight;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    if (subscription.isExpired) {
      return AppColors.inkTertiary;
    }
    return AppColors.paperOk;
  }

  /// Get the badge background color (with alpha).
  static Color getBadgeBackground(Subscription subscription) {
    return getColor(subscription).withValues(alpha: 0.1);
  }

  /// Get the border color.
  static Color getBorderColor(Subscription subscription) {
    if (subscription.isDepleted) {
      return AppColors.paperHighlight.withValues(alpha: 0.3);
    }
    if (subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    if (subscription.isExpired) {
      return AppColors.inkTertiary.withValues(alpha: 0.3);
    }
    return AppColors.inkQuaternary;
  }

  /// Get the summary text color.
  static Color getSummaryTextColor(Subscription subscription) {
    if (subscription.isDepleted) {
      return AppColors.paperHighlight;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    if (subscription.isExpired) {
      return AppColors.inkTertiary;
    }
    return AppColors.ink;
  }

  /// Get the status label text.
  static String getLabel(Subscription subscription) {
    if (subscription.isDepleted) {
      return '사용 완료';
    }
    if (subscription.isExpired) {
      return '만료됨';
    }
    if (subscription.isExpiringSoon) {
      return '갱신 필요';
    }
    if (subscription.status == SubscriptionStatus.paused) {
      return '일시정지';
    }
    return '이용중';
  }

  /// Get the status icon.
  static IconData getIcon(Subscription subscription) {
    if (subscription.isDepleted) {
      return Icons.celebration;
    }
    if (subscription.isExpired) {
      return Icons.event_busy;
    }
    if (subscription.isExpiringSoon) {
      return Icons.schedule;
    }
    if (subscription.status == SubscriptionStatus.paused) {
      return Icons.pause_circle;
    }
    return Icons.check_circle;
  }

  /// Get the status message.
  static String getMessage(Subscription subscription) {
    if (subscription.isDepleted) {
      return '수강권을 모두 사용했습니다';
    }
    if (subscription.isExpired) {
      return '수강권 유효기간이 지났습니다';
    }
    if (subscription.isExpiringSoon) {
      return '수강권 갱신이 필요합니다';
    }
    if (subscription.status == SubscriptionStatus.paused) {
      return '수강권이 일시정지 상태입니다';
    }
    return '수강권이 활성화되어 있습니다';
  }

  /// Get the border width.
  static double getBorderWidth(Subscription subscription) {
    if (subscription.isDepleted || subscription.isExpiringSoon) {
      return 2;
    }
    return 1;
  }

  /// Get the card opacity (for inactive cards).
  static double getCardOpacity(Subscription subscription) {
    if (subscription.isExpired) return 0.7;
    if (subscription.status == SubscriptionStatus.paused) return 0.8;
    return 1.0;
  }
}
