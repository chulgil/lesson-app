import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/payment.dart';

extension PaymentStatusVisuals on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return '청구됨';
      case PaymentStatus.paid:
        return '입금됨';
      case PaymentStatus.confirmed:
        return '확인완료';
      case PaymentStatus.overdue:
        return '연체';
      case PaymentStatus.cancelled:
        return '취소';
      case PaymentStatus.refunded:
        return '환불';
      // ignore: deprecated_member_use_from_same_package
      case PaymentStatus.completed:
        return '완료';
    }
  }

  Color get color {
    switch (colorKey) {
      case 'paperAccent':
        return AppColors.paperAccent;
      case 'paperOk':
        return AppColors.paperOk;
      case 'inkTertiary':
        return AppColors.inkTertiary;
      case 'ink':
        return AppColors.ink;
      default:
        return AppColors.inkTertiary;
    }
  }
}

extension PaymentTypeVisuals on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.trial:
        return '체험';
      case PaymentType.regular:
        return '정규';
    }
  }
}

extension PaymentMethodVisuals on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return '현금';
      case PaymentMethod.bankTransfer:
        return '계좌이체';
      case PaymentMethod.card:
        return '카드';
      case PaymentMethod.other:
        return '기타';
    }
  }
}

extension BillingTargetTypeVisuals on BillingTargetType {
  String get label {
    switch (this) {
      case BillingTargetType.student:
        return '학생';
      case BillingTargetType.parent:
        return '학부모';
    }
  }
}

extension PaymentVisuals on Payment {
  String get displayStatus {
    if (status == PaymentStatus.confirmed) return '확인완료';
    if (status == PaymentStatus.paid) return '입금됨';
    if (status == PaymentStatus.overdue) return '연체';
    // ignore: deprecated_member_use_from_same_package
    if (status == PaymentStatus.completed) return '완료';
    if (status == PaymentStatus.cancelled) return '취소';
    if (status == PaymentStatus.refunded) return '환불';
    if (studentConfirmed) return '입금됨';
    if (isOverdue) return '연체';
    return '청구됨';
  }

  String get formattedAmount {
    final formatter = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatter원';
  }

  String get periodDisplay {
    if (type == PaymentType.trial) {
      return '${periodStart.month}월 ${periodStart.day}일 체험';
    }
    if (weekStart != null && weekEnd != null) {
      if (weekStart == weekEnd) {
        return '${periodStart.month}월 $weekStart주';
      }
      return '${periodStart.month}월 $weekStart~$weekEnd주';
    }
    return '${periodStart.month}월 ${periodStart.day}일 ~ ${periodEnd.month}월 ${periodEnd.day}일';
  }

  String get shortDisplay {
    if (type == PaymentType.trial) {
      return '체험 · $formattedAmount';
    }
    return '$lessonCount회 · $formattedAmount';
  }

  String get billingTargetDisplayName {
    if (isBilledToParent && billingTargetName != null) {
      return '$billingTargetName (학부모)';
    }
    return '$studentName (학생)';
  }
}
