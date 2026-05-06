// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonLocation _$LessonLocationFromJson(Map<String, dynamic> json) =>
    LessonLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$LocationTypeEnumMap, json['type']),
      lessonClassId: json['lesson_class_id'] as String?,
      ownerId: json['owner_id'] as String?,
      address: json['address'] as String?,
      addressDetail: json['address_detail'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      onlinePlatform: json['online_platform'] as String?,
      onlineLink: json['online_link'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LessonLocationToJson(LessonLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$LocationTypeEnumMap[instance.type]!,
      'lesson_class_id': instance.lessonClassId,
      'owner_id': instance.ownerId,
      'address': instance.address,
      'address_detail': instance.addressDetail,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'online_platform': instance.onlinePlatform,
      'online_link': instance.onlineLink,
      'notes': instance.notes,
      'is_default': instance.isDefault,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$LocationTypeEnumMap = {
  LocationType.academyRoom: 'academyRoom',
  LocationType.teacherStudio: 'teacherStudio',
  LocationType.studentHome: 'studentHome',
  LocationType.externalPlace: 'externalPlace',
  LocationType.online: 'online',
};
