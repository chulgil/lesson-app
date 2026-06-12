// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonClass _$LessonClassFromJson(Map<String, dynamic> json) => LessonClass(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      type: $enumDecodeNullable(_$LessonClassTypeEnumMap, json['type'],
              unknownValue: LessonClassType.private) ??
          LessonClassType.private,
      paymentType: $enumDecodeNullable(
              _$PaymentTypeEnumMap, json['payment_type'],
              unknownValue: PaymentType.parent) ??
          PaymentType.parent,
      contactPerson: json['contact_person'] as String?,
      contactPhone: json['contact_phone'] as String?,
      address: json['address'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: dateTimeFromJsonOrNow(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LessonClassToJson(LessonClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'name': instance.name,
      'type': _$LessonClassTypeEnumMap[instance.type]!,
      'payment_type': _$PaymentTypeEnumMap[instance.paymentType]!,
      'contact_person': instance.contactPerson,
      'contact_phone': instance.contactPhone,
      'address': instance.address,
      'sort_order': instance.sortOrder,
      'is_archived': instance.isArchived,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$LessonClassTypeEnumMap = {
  LessonClassType.academy: 'academy',
  LessonClassType.private: 'private',
};

const _$PaymentTypeEnumMap = {
  PaymentType.organization: 'organization',
  PaymentType.parent: 'parent',
};
