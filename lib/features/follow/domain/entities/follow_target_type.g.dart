// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_target_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowTargetTypeAdapter extends TypeAdapter<FollowTargetType> {
  @override
  final int typeId = 94;

  @override
  FollowTargetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FollowTargetType.teacher;
      case 1:
        return FollowTargetType.academy;
      default:
        return FollowTargetType.teacher;
    }
  }

  @override
  void write(BinaryWriter writer, FollowTargetType obj) {
    switch (obj) {
      case FollowTargetType.teacher:
        writer.writeByte(0);
        break;
      case FollowTargetType.academy:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowTargetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
