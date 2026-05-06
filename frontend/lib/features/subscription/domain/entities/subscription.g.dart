// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
  id: json['id'] as String,
  studentId: json['student_id'] as String,
  membershipId: json['membership_id'] as String,
  paymentId: json['payment_id'] as String?,
  type: $enumDecode(_$SubscriptionTypeEnumMap, json['type']),
  totalLessons: (json['total_lessons'] as num?)?.toInt(),
  lessonsPerMonth: (json['lessons_per_month'] as num?)?.toInt(),
  usedLessons: (json['used_lessons'] as num?)?.toInt() ?? 0,
  startDate:
      json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
  endDate:
      json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
  amount: (json['amount'] as num).toInt(),
  status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  bonusCount: (json['bonus_count'] as num?)?.toInt() ?? 0,
  billingType: $enumDecodeNullable(_$BillingTypeEnumMap, json['billing_type']),
  billingDay: (json['billing_day'] as num?)?.toInt(),
  fifthWeekPolicy: $enumDecodeNullable(
    _$FifthWeekPolicyEnumMap,
    json['fifth_week_policy'],
  ),
  bonusReason: json['bonus_reason'] as String?,
  totalRescheduleAllowance:
      (json['total_reschedule_allowance'] as num?)?.toInt() ?? 2,
  usedRescheduleCount: (json['used_reschedule_count'] as num?)?.toInt() ?? 0,
  paymentConfirmed: json['payment_confirmed'] as bool? ?? true,
  paymentMethod: $enumDecodeNullable(
    _$SubscriptionPaymentMethodEnumMap,
    json['payment_method'],
  ),
  paidAt:
      json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
  paymentConfirmedAt:
      json['payment_confirmed_at'] == null
          ? null
          : DateTime.parse(json['payment_confirmed_at'] as String),
  discountAmount: (json['discount_amount'] as num?)?.toInt(),
  discountReason: json['discount_reason'] as String?,
  originalAmount: (json['original_amount'] as num?)?.toInt(),
  rescheduleDeadlineHours:
      (json['reschedule_deadline_hours'] as num?)?.toInt() ?? 12,
);

Map<String, dynamic> _$SubscriptionToJson(
  Subscription instance,
) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'membership_id': instance.membershipId,
  'payment_id': instance.paymentId,
  'type': _$SubscriptionTypeEnumMap[instance.type]!,
  'total_lessons': instance.totalLessons,
  'used_lessons': instance.usedLessons,
  'start_date': instance.startDate?.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'amount': instance.amount,
  'status': _$SubscriptionStatusEnumMap[instance.status]!,
  'lessons_per_month': instance.lessonsPerMonth,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'bonus_count': instance.bonusCount,
  'billing_type': _$BillingTypeEnumMap[instance.billingType],
  'billing_day': instance.billingDay,
  'fifth_week_policy': _$FifthWeekPolicyEnumMap[instance.fifthWeekPolicy],
  'bonus_reason': instance.bonusReason,
  'total_reschedule_allowance': instance.totalRescheduleAllowance,
  'used_reschedule_count': instance.usedRescheduleCount,
  'payment_confirmed': instance.paymentConfirmed,
  'payment_method': _$SubscriptionPaymentMethodEnumMap[instance.paymentMethod],
  'paid_at': instance.paidAt?.toIso8601String(),
  'payment_confirmed_at': instance.paymentConfirmedAt?.toIso8601String(),
  'discount_amount': instance.discountAmount,
  'discount_reason': instance.discountReason,
  'original_amount': instance.originalAmount,
  'reschedule_deadline_hours': instance.rescheduleDeadlineHours,
};

const _$SubscriptionTypeEnumMap = {
  SubscriptionType.trial: 'trial',
  SubscriptionType.monthly: 'monthly',
  SubscriptionType.package: 'package',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.expiringSoon: 'expiringSoon',
  SubscriptionStatus.expired: 'expired',
  SubscriptionStatus.paused: 'paused',
};

const _$BillingTypeEnumMap = {
  BillingType.perPackage: 'perPackage',
  BillingType.monthly: 'monthly',
};

const _$FifthWeekPolicyEnumMap = {
  FifthWeekPolicy.skip: 'skip',
  FifthWeekPolicy.bonus: 'bonus',
  FifthWeekPolicy.deduct: 'deduct',
  FifthWeekPolicy.optional: 'optional',
};

const _$SubscriptionPaymentMethodEnumMap = {
  SubscriptionPaymentMethod.cash: 'cash',
  SubscriptionPaymentMethod.bankTransfer: 'bankTransfer',
  SubscriptionPaymentMethod.card: 'card',
  SubscriptionPaymentMethod.other: 'other',
};
