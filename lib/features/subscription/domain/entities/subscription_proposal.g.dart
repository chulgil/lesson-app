// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_proposal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionProposalAdapter extends TypeAdapter<SubscriptionProposal> {
  @override
  final int typeId = 82;

  @override
  SubscriptionProposal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionProposal(
      id: fields[0] as String,
      teacherId: fields[1] as String,
      studentId: fields[2] as String,
      templateId: fields[3] as String,
      message: fields[4] as String?,
      status: fields[5] as ProposalStatus,
      createdAt: fields[6] as DateTime,
      expiresAt: fields[7] as DateTime,
      paymentNotifiedAt: fields[8] as DateTime?,
      confirmedAt: fields[9] as DateTime?,
      rejectedAt: fields[10] as DateTime?,
      subscriptionId: fields[11] as String?,
      rejectionReason: fields[12] as String?,
      academyId: fields[13] as String?,
      discountAmount: fields[14] as int?,
      discountReason: fields[15] as String?,
      templateIds: (fields[16] as List).cast<String>(),
      recommendedTemplateId: fields[17] as String?,
      selectedTemplateId: fields[18] as String?,
      isAutoProposal: fields[19] as bool,
      paymentStatus: fields[20] as ProposalPaymentStatus,
      isAppTransition: fields[21] as bool,
      lessonRequestId: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionProposal obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teacherId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.templateId)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.expiresAt)
      ..writeByte(8)
      ..write(obj.paymentNotifiedAt)
      ..writeByte(9)
      ..write(obj.confirmedAt)
      ..writeByte(10)
      ..write(obj.rejectedAt)
      ..writeByte(11)
      ..write(obj.subscriptionId)
      ..writeByte(12)
      ..write(obj.rejectionReason)
      ..writeByte(13)
      ..write(obj.academyId)
      ..writeByte(14)
      ..write(obj.discountAmount)
      ..writeByte(15)
      ..write(obj.discountReason)
      ..writeByte(16)
      ..write(obj.templateIds)
      ..writeByte(17)
      ..write(obj.recommendedTemplateId)
      ..writeByte(18)
      ..write(obj.selectedTemplateId)
      ..writeByte(19)
      ..write(obj.isAutoProposal)
      ..writeByte(20)
      ..write(obj.paymentStatus)
      ..writeByte(21)
      ..write(obj.isAppTransition)
      ..writeByte(22)
      ..write(obj.lessonRequestId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionProposalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProposalStatusAdapter extends TypeAdapter<ProposalStatus> {
  @override
  final int typeId = 81;

  @override
  ProposalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProposalStatus.pending;
      case 1:
        return ProposalStatus.paymentNotified;
      case 2:
        return ProposalStatus.confirmed;
      case 3:
        return ProposalStatus.rejected;
      case 4:
        return ProposalStatus.expired;
      case 5:
        return ProposalStatus.cancelled;
      default:
        return ProposalStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ProposalStatus obj) {
    switch (obj) {
      case ProposalStatus.pending:
        writer.writeByte(0);
        break;
      case ProposalStatus.paymentNotified:
        writer.writeByte(1);
        break;
      case ProposalStatus.confirmed:
        writer.writeByte(2);
        break;
      case ProposalStatus.rejected:
        writer.writeByte(3);
        break;
      case ProposalStatus.expired:
        writer.writeByte(4);
        break;
      case ProposalStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProposalPaymentStatusAdapter extends TypeAdapter<ProposalPaymentStatus> {
  @override
  final int typeId = 97;

  @override
  ProposalPaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProposalPaymentStatus.pending;
      case 1:
        return ProposalPaymentStatus.completed;
      default:
        return ProposalPaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ProposalPaymentStatus obj) {
    switch (obj) {
      case ProposalPaymentStatus.pending:
        writer.writeByte(0);
        break;
      case ProposalPaymentStatus.completed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalPaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionProposal _$SubscriptionProposalFromJson(
        Map<String, dynamic> json) =>
    SubscriptionProposal(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      studentId: json['studentId'] as String,
      templateId: json['templateId'] as String,
      message: json['message'] as String?,
      status: $enumDecodeNullable(_$ProposalStatusEnumMap, json['status']) ??
          ProposalStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      paymentNotifiedAt: json['paymentNotifiedAt'] == null
          ? null
          : DateTime.parse(json['paymentNotifiedAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      rejectedAt: json['rejectedAt'] == null
          ? null
          : DateTime.parse(json['rejectedAt'] as String),
      subscriptionId: json['subscriptionId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      academyId: json['academyId'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toInt(),
      discountReason: json['discountReason'] as String?,
      templateIds: (json['templateIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendedTemplateId: json['recommendedTemplateId'] as String?,
      selectedTemplateId: json['selectedTemplateId'] as String?,
      isAutoProposal: json['isAutoProposal'] as bool? ?? false,
      paymentStatus: $enumDecodeNullable(
              _$ProposalPaymentStatusEnumMap, json['paymentStatus']) ??
          ProposalPaymentStatus.pending,
      isAppTransition: json['isAppTransition'] as bool? ?? false,
      lessonRequestId: json['lessonRequestId'] as String?,
    );

Map<String, dynamic> _$SubscriptionProposalToJson(
        SubscriptionProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'studentId': instance.studentId,
      'templateId': instance.templateId,
      'message': instance.message,
      'status': _$ProposalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'paymentNotifiedAt': instance.paymentNotifiedAt?.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'rejectedAt': instance.rejectedAt?.toIso8601String(),
      'subscriptionId': instance.subscriptionId,
      'rejectionReason': instance.rejectionReason,
      'academyId': instance.academyId,
      'discountAmount': instance.discountAmount,
      'discountReason': instance.discountReason,
      'templateIds': instance.templateIds,
      'recommendedTemplateId': instance.recommendedTemplateId,
      'selectedTemplateId': instance.selectedTemplateId,
      'isAutoProposal': instance.isAutoProposal,
      'paymentStatus': _$ProposalPaymentStatusEnumMap[instance.paymentStatus]!,
      'isAppTransition': instance.isAppTransition,
      'lessonRequestId': instance.lessonRequestId,
    };

const _$ProposalStatusEnumMap = {
  ProposalStatus.pending: 'pending',
  ProposalStatus.paymentNotified: 'paymentNotified',
  ProposalStatus.confirmed: 'confirmed',
  ProposalStatus.rejected: 'rejected',
  ProposalStatus.expired: 'expired',
  ProposalStatus.cancelled: 'cancelled',
};

const _$ProposalPaymentStatusEnumMap = {
  ProposalPaymentStatus.pending: 'pending',
  ProposalPaymentStatus.completed: 'completed',
};
