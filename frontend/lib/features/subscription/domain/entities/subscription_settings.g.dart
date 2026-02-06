// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PackageDiscountPolicyAdapter extends TypeAdapter<PackageDiscountPolicy> {
  @override
  final int typeId = 61;

  @override
  PackageDiscountPolicy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PackageDiscountPolicy(
      minLessons: fields[0] as int,
      type: fields[1] as DiscountType,
      value: fields[2] as int,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PackageDiscountPolicy obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.minLessons)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageDiscountPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionSettingsAdapter extends TypeAdapter<SubscriptionSettings> {
  @override
  final int typeId = 62;

  @override
  SubscriptionSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionSettings(
      id: fields[0] as String,
      teacherId: fields[1] as String?,
      organizationId: fields[2] as String?,
      renewalAlertThreshold: fields[3] as int,
      renewalAlertDays: fields[4] as int,
      discountPolicies: (fields[5] as List).cast<PackageDiscountPolicy>(),
      enablePushNotification: fields[6] as bool,
      enableBadge: fields[7] as bool,
      notifyParent: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.organizationId)
      ..writeByte(3)
      ..write(obj.renewalAlertThreshold)
      ..writeByte(4)
      ..write(obj.renewalAlertDays)
      ..writeByte(5)
      ..write(obj.discountPolicies)
      ..writeByte(6)
      ..write(obj.enablePushNotification)
      ..writeByte(7)
      ..write(obj.enableBadge)
      ..writeByte(8)
      ..write(obj.notifyParent)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountTypeAdapter extends TypeAdapter<DiscountType> {
  @override
  final int typeId = 60;

  @override
  DiscountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiscountType.discount;
      case 1:
        return DiscountType.bonusLessons;
      default:
        return DiscountType.discount;
    }
  }

  @override
  void write(BinaryWriter writer, DiscountType obj) {
    switch (obj) {
      case DiscountType.discount:
        writer.writeByte(0);
        break;
      case DiscountType.bonusLessons:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageDiscountPolicy _$PackageDiscountPolicyFromJson(
        Map<String, dynamic> json) =>
    PackageDiscountPolicy(
      minLessons: (json['minLessons'] as num).toInt(),
      type: $enumDecode(_$DiscountTypeEnumMap, json['type']),
      value: (json['value'] as num).toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PackageDiscountPolicyToJson(
        PackageDiscountPolicy instance) =>
    <String, dynamic>{
      'minLessons': instance.minLessons,
      'type': _$DiscountTypeEnumMap[instance.type]!,
      'value': instance.value,
      'description': instance.description,
    };

const _$DiscountTypeEnumMap = {
  DiscountType.discount: 'discount',
  DiscountType.bonusLessons: 'bonusLessons',
};

SubscriptionSettings _$SubscriptionSettingsFromJson(
        Map<String, dynamic> json) =>
    SubscriptionSettings(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String?,
      organizationId: json['organizationId'] as String?,
      renewalAlertThreshold:
          (json['renewalAlertThreshold'] as num?)?.toInt() ?? 1,
      renewalAlertDays: (json['renewalAlertDays'] as num?)?.toInt() ?? 7,
      discountPolicies: (json['discountPolicies'] as List<dynamic>?)
              ?.map((e) =>
                  PackageDiscountPolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      enablePushNotification: json['enablePushNotification'] as bool? ?? true,
      enableBadge: json['enableBadge'] as bool? ?? true,
      notifyParent: json['notifyParent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionSettingsToJson(
        SubscriptionSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'organizationId': instance.organizationId,
      'renewalAlertThreshold': instance.renewalAlertThreshold,
      'renewalAlertDays': instance.renewalAlertDays,
      'discountPolicies': instance.discountPolicies,
      'enablePushNotification': instance.enablePushNotification,
      'enableBadge': instance.enableBadge,
      'notifyParent': instance.notifyParent,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
