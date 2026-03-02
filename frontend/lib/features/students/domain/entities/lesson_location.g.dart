// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonLocationAdapter extends TypeAdapter<LessonLocation> {
  @override
  final int typeId = 59;

  @override
  LessonLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonLocation(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as LocationType,
      lessonClassId: fields[3] as String?,
      ownerId: fields[4] as String?,
      address: fields[5] as String?,
      addressDetail: fields[6] as String?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      onlinePlatform: fields[9] as String?,
      onlineLink: fields[10] as String?,
      notes: fields[11] as String?,
      isDefault: fields[12] as bool,
      isActive: fields[13] as bool,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonLocation obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.lessonClassId)
      ..writeByte(4)
      ..write(obj.ownerId)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.addressDetail)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.onlinePlatform)
      ..writeByte(10)
      ..write(obj.onlineLink)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isDefault)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationTypeAdapter extends TypeAdapter<LocationType> {
  @override
  final int typeId = 58;

  @override
  LocationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LocationType.academyRoom;
      case 1:
        return LocationType.teacherStudio;
      case 2:
        return LocationType.studentHome;
      case 3:
        return LocationType.externalPlace;
      case 4:
        return LocationType.online;
      default:
        return LocationType.academyRoom;
    }
  }

  @override
  void write(BinaryWriter writer, LocationType obj) {
    switch (obj) {
      case LocationType.academyRoom:
        writer.writeByte(0);
        break;
      case LocationType.teacherStudio:
        writer.writeByte(1);
        break;
      case LocationType.studentHome:
        writer.writeByte(2);
        break;
      case LocationType.externalPlace:
        writer.writeByte(3);
        break;
      case LocationType.online:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
