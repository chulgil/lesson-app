// Payment domain entity
// Moved from lib/features/lessons/domain/entities/payment.dart for Clean Architecture

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// Payment type enum (trial vs regular)
enum PaymentType {
  trial,   // 체험 레슨
  regular; // 정규 레슨

  String get label {
    switch (this) {
      case PaymentType.trial:
        return '체험';
      case PaymentType.regular:
        return '정규';
    }
  }
}

/// Payment status enum (V2: state-transition based flow)
enum PaymentStatus {
  pending,    // 청구됨 (입금 대기)
  paid,       // 입금됨 (학생/학부모가 입금 기록)
  confirmed,  // 확인 완료 (선생님이 입금 확인)
  overdue,    // 연체 (마감일 초과)
  cancelled,  // 취소됨
  refunded,   // 환불됨
  @Deprecated('Use confirmed instead. Kept for backwards compatibility.')
  completed;  // V1 완료 → V2 confirmed로 마이그레이션 예정

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
        return '완료'; // Legacy
    }
  }

  /// V2: Get color for status indicator
  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.paid:
        return AppColors.info;
      case PaymentStatus.confirmed:
      // ignore: deprecated_member_use_from_same_package
      case PaymentStatus.completed:
        return AppColors.success;
      case PaymentStatus.overdue:
        return AppColors.error;
      case PaymentStatus.cancelled:
      case PaymentStatus.refunded:
        return AppColors.textTertiaryLight;
    }
  }

  /// V2: Check if payment requires action
  bool get requiresAction => this == PaymentStatus.pending || this == PaymentStatus.paid;

  /// V2: Check if payment is finalized
  bool get isFinalized =>
      this == PaymentStatus.confirmed ||
      // ignore: deprecated_member_use_from_same_package
      this == PaymentStatus.completed ||
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.refunded;
}

/// Payment method enum
enum PaymentMethod {
  cash,
  bankTransfer,
  card,
  other;

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

/// Billing target type enum
enum BillingTargetType {
  student, // Default: student pays themselves
  parent;  // Parent is the billing target

  String get label {
    switch (this) {
      case BillingTargetType.student:
        return '학생';
      case BillingTargetType.parent:
        return '학부모';
    }
  }
}

/// Payment record model
@JsonSerializable()
class Payment {
  final String id;
  final String studentId;
  final String studentName;
  final PaymentType type; // Trial or Regular
  final int amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final String? description;
  final String? receiptNumber;
  final int lessonCount; // Number of lessons this payment covers
  final DateTime periodStart; // Period this payment covers
  final DateTime periodEnd;
  final int? weekStart; // Starting week (1-5)
  final int? weekEnd; // Ending week (1-5)
  final bool studentConfirmed; // Student claimed payment complete
  final DateTime? studentConfirmedAt; // When student confirmed
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Parent billing support
  final BillingTargetType billingTargetType; // Who is the billing target
  final String? billingTargetId; // Parent ID if parent is billing target
  final String? billingTargetName; // Parent name for display

  // V2: State transition timestamps
  final DateTime? paidAt; // When student/parent recorded payment (maps to studentConfirmedAt)
  final String? paidBy; // Who recorded the payment (student or parent ID)
  final DateTime? confirmedAt; // When teacher confirmed the payment
  final String? confirmedBy; // Who confirmed the payment (teacher ID)
  final bool parentNotified; // Has parent been notified of this payment request
  final DateTime? parentNotifiedAt; // When parent was notified

  const Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.type = PaymentType.regular,
    required this.amount,
    this.status = PaymentStatus.pending,
    this.method = PaymentMethod.bankTransfer,
    required this.paymentDate,
    this.dueDate,
    this.description,
    this.receiptNumber,
    this.lessonCount = 4,
    required this.periodStart,
    required this.periodEnd,
    this.weekStart,
    this.weekEnd,
    this.studentConfirmed = false,
    this.studentConfirmedAt,
    required this.createdAt,
    this.updatedAt,
    this.billingTargetType = BillingTargetType.student,
    this.billingTargetId,
    this.billingTargetName,
    this.paidAt,
    this.paidBy,
    this.confirmedAt,
    this.confirmedBy,
    this.parentNotified = false,
    this.parentNotifiedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  /// Check if payment is overdue
  bool get isOverdue =>
      status == PaymentStatus.pending &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  /// Check if awaiting teacher confirmation (student confirmed but not teacher)
  bool get isAwaitingTeacherConfirmation =>
      status == PaymentStatus.pending && studentConfirmed;

  /// Get display status considering V2 state-transition flow
  String get displayStatus {
    // V2 status values
    if (status == PaymentStatus.confirmed) return '확인완료';
    if (status == PaymentStatus.paid) return '입금됨';
    if (status == PaymentStatus.overdue) return '연체';
    // Legacy status values
    // ignore: deprecated_member_use_from_same_package
    if (status == PaymentStatus.completed) return '완료';
    if (status == PaymentStatus.cancelled) return '취소';
    if (status == PaymentStatus.refunded) return '환불';
    // V1 fallback: use studentConfirmed flag
    if (studentConfirmed) return '입금됨';
    if (isOverdue) return '연체';
    return '청구됨';
  }

  /// V2: Get effective status considering both V1 and V2 fields
  PaymentStatus get effectiveStatus {
    // If already using V2 status, return as-is
    if (status == PaymentStatus.paid ||
        status == PaymentStatus.confirmed ||
        status == PaymentStatus.overdue) {
      return status;
    }
    // V1 to V2 mapping
    // ignore: deprecated_member_use_from_same_package
    if (status == PaymentStatus.completed) return PaymentStatus.confirmed;
    if (status == PaymentStatus.pending && studentConfirmed) {
      return PaymentStatus.paid;
    }
    if (isOverdue) return PaymentStatus.overdue;
    return status;
  }

  /// Format amount as Korean won
  String get formattedAmount {
    final formatter = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }

  /// Get period display string
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

  /// Get short display for list
  String get shortDisplay {
    if (type == PaymentType.trial) {
      return '체험 · $formattedAmount';
    }
    return '$lessonCount회 · $formattedAmount';
  }

  /// Check if parent is the billing target
  bool get isBilledToParent => billingTargetType == BillingTargetType.parent;

  /// Get billing target display name
  String get billingTargetDisplayName {
    if (isBilledToParent && billingTargetName != null) {
      return '$billingTargetName (학부모)';
    }
    return '$studentName (학생)';
  }

  Payment copyWith({
    String? id,
    String? studentId,
    String? studentName,
    PaymentType? type,
    int? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? paymentDate,
    DateTime? dueDate,
    String? description,
    String? receiptNumber,
    int? lessonCount,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? weekStart,
    int? weekEnd,
    bool? studentConfirmed,
    DateTime? studentConfirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    BillingTargetType? billingTargetType,
    String? billingTargetId,
    String? billingTargetName,
    DateTime? paidAt,
    String? paidBy,
    DateTime? confirmedAt,
    String? confirmedBy,
    bool? parentNotified,
    DateTime? parentNotifiedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      lessonCount: lessonCount ?? this.lessonCount,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      studentConfirmed: studentConfirmed ?? this.studentConfirmed,
      studentConfirmedAt: studentConfirmedAt ?? this.studentConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billingTargetType: billingTargetType ?? this.billingTargetType,
      billingTargetId: billingTargetId ?? this.billingTargetId,
      billingTargetName: billingTargetName ?? this.billingTargetName,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      parentNotified: parentNotified ?? this.parentNotified,
      parentNotifiedAt: parentNotifiedAt ?? this.parentNotifiedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Tuition settings for a student
@JsonSerializable()
class TuitionSettings {
  final String studentId;
  final int monthlyFee; // Monthly tuition fee
  final int lessonFee; // Fee per lesson (alternative to monthly)
  final bool isMonthlyBilling; // true: monthly, false: per lesson
  final int lessonsPerMonth; // Expected lessons per month
  final int billingDay; // Day of month for billing (1-28)
  final PaymentMethod preferredMethod;
  final String? bankAccount; // For bank transfer
  final String? notes;
  final DateTime? lastPaymentDate;
  final DateTime? nextDueDate;

  // Parent billing support
  final BillingTargetType defaultBillingTarget; // Default billing target
  final String? defaultBillingParentId; // Default parent to bill

  const TuitionSettings({
    required this.studentId,
    this.monthlyFee = 200000,
    this.lessonFee = 50000,
    this.isMonthlyBilling = true,
    this.lessonsPerMonth = 4,
    this.billingDay = 1,
    this.preferredMethod = PaymentMethod.bankTransfer,
    this.bankAccount,
    this.notes,
    this.lastPaymentDate,
    this.nextDueDate,
    this.defaultBillingTarget = BillingTargetType.parent, // Default to parent
    this.defaultBillingParentId,
  });

  factory TuitionSettings.fromJson(Map<String, dynamic> json) =>
      _$TuitionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$TuitionSettingsToJson(this);

  /// Calculate effective per-lesson cost
  int get effectiveLessonFee {
    if (!isMonthlyBilling) return lessonFee;
    if (lessonsPerMonth == 0) return 0;
    return (monthlyFee / lessonsPerMonth).round();
  }

  /// Format monthly fee
  String get formattedMonthlyFee {
    final formatter = monthlyFee.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }

  /// Format lesson fee
  String get formattedLessonFee {
    final formatter = lessonFee.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }

  TuitionSettings copyWith({
    String? studentId,
    int? monthlyFee,
    int? lessonFee,
    bool? isMonthlyBilling,
    int? lessonsPerMonth,
    int? billingDay,
    PaymentMethod? preferredMethod,
    String? bankAccount,
    String? notes,
    DateTime? lastPaymentDate,
    DateTime? nextDueDate,
    BillingTargetType? defaultBillingTarget,
    String? defaultBillingParentId,
  }) {
    return TuitionSettings(
      studentId: studentId ?? this.studentId,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      lessonFee: lessonFee ?? this.lessonFee,
      isMonthlyBilling: isMonthlyBilling ?? this.isMonthlyBilling,
      lessonsPerMonth: lessonsPerMonth ?? this.lessonsPerMonth,
      billingDay: billingDay ?? this.billingDay,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      bankAccount: bankAccount ?? this.bankAccount,
      notes: notes ?? this.notes,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      defaultBillingTarget: defaultBillingTarget ?? this.defaultBillingTarget,
      defaultBillingParentId:
          defaultBillingParentId ?? this.defaultBillingParentId,
    );
  }
}

/// Payment summary statistics
@JsonSerializable()
class PaymentSummary {
  final int totalReceived; // Total amount received this month
  final int totalPending; // Total pending amount
  final int totalOverdue; // Total overdue amount
  final int paidStudents; // Number of students who paid
  final int unpaidStudents; // Number of students who haven't paid
  final int overdueStudents; // Number of students with overdue payments

  const PaymentSummary({
    this.totalReceived = 0,
    this.totalPending = 0,
    this.totalOverdue = 0,
    this.paidStudents = 0,
    this.unpaidStudents = 0,
    this.overdueStudents = 0,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      _$PaymentSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSummaryToJson(this);

  /// Format total received
  String get formattedTotalReceived {
    final formatter = totalReceived.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }

  /// Format total pending
  String get formattedTotalPending {
    final formatter = totalPending.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatter원';
  }
}
