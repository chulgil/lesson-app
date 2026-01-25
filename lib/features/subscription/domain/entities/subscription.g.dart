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
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.bonusReason);
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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      membershipId: json['membershipId'] as String,
      paymentId: json['paymentId'] as String?,
      type: $enumDecode(_$SubscriptionTypeEnumMap, json['type']),
      totalLessons: (json['totalLessons'] as num?)?.toInt(),
      lessonsPerMonth: (json['lessonsPerMonth'] as num?)?.toInt(),
      usedLessons: (json['usedLessons'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      amount: (json['amount'] as num).toInt(),
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      bonusCount: (json['bonusCount'] as num?)?.toInt() ?? 0,
      billingType:
          $enumDecodeNullable(_$BillingTypeEnumMap, json['billingType']),
      billingDay: (json['billingDay'] as num?)?.toInt(),
      fifthWeekPolicy: $enumDecodeNullable(
          _$FifthWeekPolicyEnumMap, json['fifthWeekPolicy']),
      bonusReason: json['bonusReason'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'membershipId': instance.membershipId,
      'paymentId': instance.paymentId,
      'type': _$SubscriptionTypeEnumMap[instance.type]!,
      'totalLessons': instance.totalLessons,
      'usedLessons': instance.usedLessons,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'amount': instance.amount,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'lessonsPerMonth': instance.lessonsPerMonth,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'bonusCount': instance.bonusCount,
      'billingType': _$BillingTypeEnumMap[instance.billingType],
      'billingDay': instance.billingDay,
      'fifthWeekPolicy': _$FifthWeekPolicyEnumMap[instance.fifthWeekPolicy],
      'bonusReason': instance.bonusReason,
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
