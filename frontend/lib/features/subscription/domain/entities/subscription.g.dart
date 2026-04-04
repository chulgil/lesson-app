// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 57;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      studentId: fields[1] as String,
      membershipId: fields[2] as String,
      paymentId: fields[3] as String?,
      type: fields[4] as SubscriptionType,
      totalLessons: fields[5] as int?,
      lessonsPerMonth: fields[13] as int?,
      usedLessons: fields[6] as int,
      startDate: fields[7] as DateTime?,
      endDate: fields[8] as DateTime?,
      amount: fields[9] as int,
      status: fields[10] as SubscriptionStatus,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
      bonusCount: fields[14] as int,
      billingType: fields[15] as BillingType?,
      billingDay: fields[16] as int?,
      fifthWeekPolicy: fields[17] as FifthWeekPolicy?,
      bonusReason: fields[18] as String?,
      totalRescheduleAllowance: fields[19] as int,
      usedRescheduleCount: fields[20] as int,
      paymentConfirmed: fields[21] as bool,
      paymentMethod: fields[22] as SubscriptionPaymentMethod?,
      paidAt: fields[23] as DateTime?,
      paymentConfirmedAt: fields[24] as DateTime?,
      discountAmount: fields[25] as int?,
      discountReason: fields[26] as String?,
      originalAmount: fields[27] as int?,
      rescheduleDeadlineHours: fields[28] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.membershipId)
      ..writeByte(3)
      ..write(obj.paymentId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.totalLessons)
      ..writeByte(6)
      ..write(obj.usedLessons)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.amount)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.lessonsPerMonth)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.bonusCount)
      ..writeByte(15)
      ..write(obj.billingType)
      ..writeByte(16)
      ..write(obj.billingDay)
      ..writeByte(17)
      ..write(obj.fifthWeekPolicy)
      ..writeByte(18)
      ..write(obj.bonusReason)
      ..writeByte(19)
      ..write(obj.totalRescheduleAllowance)
      ..writeByte(20)
      ..write(obj.usedRescheduleCount)
      ..writeByte(21)
      ..write(obj.paymentConfirmed)
      ..writeByte(22)
      ..write(obj.paymentMethod)
      ..writeByte(23)
      ..write(obj.paidAt)
      ..writeByte(24)
      ..write(obj.paymentConfirmedAt)
      ..writeByte(25)
      ..write(obj.discountAmount)
      ..writeByte(26)
      ..write(obj.discountReason)
      ..writeByte(27)
      ..write(obj.originalAmount)
      ..writeByte(28)
      ..write(obj.rescheduleDeadlineHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionTypeAdapter extends TypeAdapter<SubscriptionType> {
  @override
  final int typeId = 55;

  @override
  SubscriptionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionType.trial;
      case 1:
        return SubscriptionType.monthly;
      case 2:
        return SubscriptionType.package;
      default:
        return SubscriptionType.trial;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionType obj) {
    switch (obj) {
      case SubscriptionType.trial:
        writer.writeByte(0);
        break;
      case SubscriptionType.monthly:
        writer.writeByte(1);
        break;
      case SubscriptionType.package:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionStatusAdapter extends TypeAdapter<SubscriptionStatus> {
  @override
  final int typeId = 56;

  @override
  SubscriptionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionStatus.active;
      case 1:
        return SubscriptionStatus.expiringSoon;
      case 2:
        return SubscriptionStatus.expired;
      case 3:
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    switch (obj) {
      case SubscriptionStatus.active:
        writer.writeByte(0);
        break;
      case SubscriptionStatus.expiringSoon:
        writer.writeByte(1);
        break;
      case SubscriptionStatus.expired:
        writer.writeByte(2);
        break;
      case SubscriptionStatus.paused:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillingTypeAdapter extends TypeAdapter<BillingType> {
  @override
  final int typeId = 58;

  @override
  BillingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BillingType.perPackage;
      case 1:
        return BillingType.monthly;
      default:
        return BillingType.perPackage;
    }
  }

  @override
  void write(BinaryWriter writer, BillingType obj) {
    switch (obj) {
      case BillingType.perPackage:
        writer.writeByte(0);
        break;
      case BillingType.monthly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FifthWeekPolicyAdapter extends TypeAdapter<FifthWeekPolicy> {
  @override
  final int typeId = 59;

  @override
  FifthWeekPolicy read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FifthWeekPolicy.skip;
      case 1:
        return FifthWeekPolicy.bonus;
      case 2:
        return FifthWeekPolicy.deduct;
      case 3:
        return FifthWeekPolicy.optional;
      default:
        return FifthWeekPolicy.skip;
    }
  }

  @override
  void write(BinaryWriter writer, FifthWeekPolicy obj) {
    switch (obj) {
      case FifthWeekPolicy.skip:
        writer.writeByte(0);
        break;
      case FifthWeekPolicy.bonus:
        writer.writeByte(1);
        break;
      case FifthWeekPolicy.deduct:
        writer.writeByte(2);
        break;
      case FifthWeekPolicy.optional:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FifthWeekPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionPaymentMethodAdapter
    extends TypeAdapter<SubscriptionPaymentMethod> {
  @override
  final int typeId = 99;

  @override
  SubscriptionPaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionPaymentMethod.cash;
      case 1:
        return SubscriptionPaymentMethod.bankTransfer;
      case 2:
        return SubscriptionPaymentMethod.card;
      case 3:
        return SubscriptionPaymentMethod.other;
      default:
        return SubscriptionPaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionPaymentMethod obj) {
    switch (obj) {
      case SubscriptionPaymentMethod.cash:
        writer.writeByte(0);
        break;
      case SubscriptionPaymentMethod.bankTransfer:
        writer.writeByte(1);
        break;
      case SubscriptionPaymentMethod.card:
        writer.writeByte(2);
        break;
      case SubscriptionPaymentMethod.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      amount: (json['amount'] as num).toInt(),
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      bonusCount: (json['bonus_count'] as num?)?.toInt() ?? 0,
      billingType:
          $enumDecodeNullable(_$BillingTypeEnumMap, json['billing_type']),
      billingDay: (json['billing_day'] as num?)?.toInt(),
      fifthWeekPolicy: $enumDecodeNullable(
          _$FifthWeekPolicyEnumMap, json['fifth_week_policy']),
      bonusReason: json['bonus_reason'] as String?,
      totalRescheduleAllowance:
          (json['total_reschedule_allowance'] as num?)?.toInt() ?? 2,
      usedRescheduleCount:
          (json['used_reschedule_count'] as num?)?.toInt() ?? 0,
      paymentConfirmed: json['payment_confirmed'] as bool? ?? true,
      paymentMethod: $enumDecodeNullable(
          _$SubscriptionPaymentMethodEnumMap, json['payment_method']),
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      paymentConfirmedAt: json['payment_confirmed_at'] == null
          ? null
          : DateTime.parse(json['payment_confirmed_at'] as String),
      discountAmount: (json['discount_amount'] as num?)?.toInt(),
      discountReason: json['discount_reason'] as String?,
      originalAmount: (json['original_amount'] as num?)?.toInt(),
      rescheduleDeadlineHours:
          (json['reschedule_deadline_hours'] as num?)?.toInt() ?? 12,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
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
      'payment_method':
          _$SubscriptionPaymentMethodEnumMap[instance.paymentMethod],
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
