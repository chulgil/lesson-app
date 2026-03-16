// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      type: $enumDecodeNullable(_$PaymentTypeEnumMap, json['type']) ??
          PaymentType.regular,
      amount: (json['amount'] as num).toInt(),
      status: $enumDecodeNullable(_$PaymentStatusEnumMap, json['status']) ??
          PaymentStatus.pending,
      method: $enumDecodeNullable(_$PaymentMethodEnumMap, json['method']) ??
          PaymentMethod.bankTransfer,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      description: json['description'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 4,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      weekStart: (json['week_start'] as num?)?.toInt(),
      weekEnd: (json['week_end'] as num?)?.toInt(),
      studentConfirmed: json['student_confirmed'] as bool? ?? false,
      studentConfirmedAt: json['student_confirmed_at'] == null
          ? null
          : DateTime.parse(json['student_confirmed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      billingTargetType: $enumDecodeNullable(
              _$BillingTargetTypeEnumMap, json['billing_target_type']) ??
          BillingTargetType.student,
      billingTargetId: json['billing_target_id'] as String?,
      billingTargetName: json['billing_target_name'] as String?,
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      paidBy: json['paid_by'] as String?,
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      confirmedBy: json['confirmed_by'] as String?,
      parentNotified: json['parent_notified'] as bool? ?? false,
      parentNotifiedAt: json['parent_notified_at'] == null
          ? null
          : DateTime.parse(json['parent_notified_at'] as String),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'student_name': instance.studentName,
      'type': _$PaymentTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'payment_date': instance.paymentDate.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'description': instance.description,
      'receipt_number': instance.receiptNumber,
      'lesson_count': instance.lessonCount,
      'period_start': instance.periodStart.toIso8601String(),
      'period_end': instance.periodEnd.toIso8601String(),
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'student_confirmed': instance.studentConfirmed,
      'student_confirmed_at': instance.studentConfirmedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'billing_target_type':
          _$BillingTargetTypeEnumMap[instance.billingTargetType]!,
      'billing_target_id': instance.billingTargetId,
      'billing_target_name': instance.billingTargetName,
      'paid_at': instance.paidAt?.toIso8601String(),
      'paid_by': instance.paidBy,
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'confirmed_by': instance.confirmedBy,
      'parent_notified': instance.parentNotified,
      'parent_notified_at': instance.parentNotifiedAt?.toIso8601String(),
    };

const _$PaymentTypeEnumMap = {
  PaymentType.trial: 'trial',
  PaymentType.regular: 'regular',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.confirmed: 'confirmed',
  PaymentStatus.overdue: 'overdue',
  PaymentStatus.cancelled: 'cancelled',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.completed: 'completed',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.bankTransfer: 'bankTransfer',
  PaymentMethod.card: 'card',
  PaymentMethod.other: 'other',
};

const _$BillingTargetTypeEnumMap = {
  BillingTargetType.student: 'student',
  BillingTargetType.parent: 'parent',
};

TuitionSettings _$TuitionSettingsFromJson(Map<String, dynamic> json) =>
    TuitionSettings(
      studentId: json['student_id'] as String,
      monthlyFee: (json['monthly_fee'] as num?)?.toInt() ?? 200000,
      lessonFee: (json['lesson_fee'] as num?)?.toInt() ?? 50000,
      isMonthlyBilling: json['is_monthly_billing'] as bool? ?? true,
      lessonsPerMonth: (json['lessons_per_month'] as num?)?.toInt() ?? 4,
      billingDay: (json['billing_day'] as num?)?.toInt() ?? 1,
      preferredMethod: $enumDecodeNullable(
              _$PaymentMethodEnumMap, json['preferred_method']) ??
          PaymentMethod.bankTransfer,
      bankAccount: json['bank_account'] as String?,
      notes: json['notes'] as String?,
      lastPaymentDate: json['last_payment_date'] == null
          ? null
          : DateTime.parse(json['last_payment_date'] as String),
      nextDueDate: json['next_due_date'] == null
          ? null
          : DateTime.parse(json['next_due_date'] as String),
      defaultBillingTarget: $enumDecodeNullable(
              _$BillingTargetTypeEnumMap, json['default_billing_target']) ??
          BillingTargetType.parent,
      defaultBillingParentId: json['default_billing_parent_id'] as String?,
    );

Map<String, dynamic> _$TuitionSettingsToJson(TuitionSettings instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'monthly_fee': instance.monthlyFee,
      'lesson_fee': instance.lessonFee,
      'is_monthly_billing': instance.isMonthlyBilling,
      'lessons_per_month': instance.lessonsPerMonth,
      'billing_day': instance.billingDay,
      'preferred_method': _$PaymentMethodEnumMap[instance.preferredMethod]!,
      'bank_account': instance.bankAccount,
      'notes': instance.notes,
      'last_payment_date': instance.lastPaymentDate?.toIso8601String(),
      'next_due_date': instance.nextDueDate?.toIso8601String(),
      'default_billing_target':
          _$BillingTargetTypeEnumMap[instance.defaultBillingTarget]!,
      'default_billing_parent_id': instance.defaultBillingParentId,
    };

PaymentSummary _$PaymentSummaryFromJson(Map<String, dynamic> json) =>
    PaymentSummary(
      totalReceived: (json['total_received'] as num?)?.toInt() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toInt() ?? 0,
      totalOverdue: (json['total_overdue'] as num?)?.toInt() ?? 0,
      paidStudents: (json['paid_students'] as num?)?.toInt() ?? 0,
      unpaidStudents: (json['unpaid_students'] as num?)?.toInt() ?? 0,
      overdueStudents: (json['overdue_students'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PaymentSummaryToJson(PaymentSummary instance) =>
    <String, dynamic>{
      'total_received': instance.totalReceived,
      'total_pending': instance.totalPending,
      'total_overdue': instance.totalOverdue,
      'paid_students': instance.paidStudents,
      'unpaid_students': instance.unpaidStudents,
      'overdue_students': instance.overdueStudents,
    };
