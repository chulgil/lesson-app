// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonClassAdapter extends TypeAdapter<LessonClass> {
  @override
  final int typeId = 52;

  @override
  LessonClass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonClass(
      id: fields[0] as String,
      teacherId: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as LessonClassType,
      paymentType: fields[4] as PaymentType,
      contactPerson: fields[5] as String?,
      contactPhone: fields[6] as String?,
      address: fields[7] as String?,
      sortOrder: fields[8] as int,
      isArchived: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonClass obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.paymentType)
      ..writeByte(5)
      ..write(obj.contactPerson)
      ..writeByte(6)
      ..write(obj.contactPhone)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.isArchived)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LessonClassTypeAdapter extends TypeAdapter<LessonClassType> {
  @override
  final int typeId = 50;

  @override
  LessonClassType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LessonClassType.academy;
      case 1:
        return LessonClassType.private;
      default:
        return LessonClassType.academy;
    }
  }

  @override
  void write(BinaryWriter writer, LessonClassType obj) {
    switch (obj) {
      case LessonClassType.academy:
        writer.writeByte(0);
        break;
      case LessonClassType.private:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonClassTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentTypeAdapter extends TypeAdapter<PaymentType> {
  @override
  final int typeId = 51;

  @override
  PaymentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentType.organization;
      case 1:
        return PaymentType.parent;
      default:
        return PaymentType.organization;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentType obj) {
    switch (obj) {
      case PaymentType.organization:
        writer.writeByte(0);
        break;
      case PaymentType.parent:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonClass _$LessonClassFromJson(Map<String, dynamic> json) => LessonClass(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$LessonClassTypeEnumMap, json['type']),
      paymentType: $enumDecode(_$PaymentTypeEnumMap, json['paymentType']),
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      address: json['address'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LessonClassToJson(LessonClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'name': instance.name,
      'type': _$LessonClassTypeEnumMap[instance.type]!,
      'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
      'contactPerson': instance.contactPerson,
      'contactPhone': instance.contactPhone,
      'address': instance.address,
      'sortOrder': instance.sortOrder,
      'isArchived': instance.isArchived,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$LessonClassTypeEnumMap = {
  LessonClassType.academy: 'academy',
  LessonClassType.private: 'private',
};

const _$PaymentTypeEnumMap = {
  PaymentType.organization: 'organization',
  PaymentType.parent: 'parent',
};
