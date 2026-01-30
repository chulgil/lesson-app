// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RelationshipStatusAdapter extends TypeAdapter<RelationshipStatus> {
  @override
  final int typeId = 91;

  @override
  RelationshipStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RelationshipStatus.trialBooked;
      case 1:
        return RelationshipStatus.active;
      case 2:
        return RelationshipStatus.expired;
      case 3:
        return RelationshipStatus.past;
      default:
        return RelationshipStatus.trialBooked;
    }
  }

  @override
  void write(BinaryWriter writer, RelationshipStatus obj) {
    switch (obj) {
      case RelationshipStatus.trialBooked:
        writer.writeByte(0);
        break;
      case RelationshipStatus.active:
        writer.writeByte(1);
        break;
      case RelationshipStatus.expired:
        writer.writeByte(2);
        break;
      case RelationshipStatus.past:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
