// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_lesson_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeSlotOptionAdapter extends TypeAdapter<TimeSlotOption> {
  @override
  final int typeId = 126;

  @override
  TimeSlotOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeSlotOption(
      id: fields[0] as String,
      dayOfWeek: fields[1] as int,
      startTime: fields[2] as String,
      endTime: fields[3] as String,
      isSelected: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimeSlotOption obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dayOfWeek)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.isSelected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeProposalAdapter extends TypeAdapter<TimeProposal> {
  @override
  final int typeId = 127;

  @override
  TimeProposal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeProposal(
      id: fields[0] as String,
      proposerId: fields[1] as String,
      role: fields[2] as ProposerRole,
      slots: (fields[3] as List).cast<TimeSlotOption>(),
      message: fields[4] as String?,
      action: fields[5] as ProposalAction,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimeProposal obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.proposerId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.slots)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.action)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeProposalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PreferredTimeSlotAdapter extends TypeAdapter<PreferredTimeSlot> {
  @override
  final int typeId = 129;

  @override
  PreferredTimeSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreferredTimeSlot(
      priority: fields[0] as int,
      date: fields[1] as DateTime?,
      dayOfWeek: fields[2] as int?,
      startTime: fields[3] as String,
      endTime: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PreferredTimeSlot obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.priority)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferredTimeSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedLessonRequestAdapter extends TypeAdapter<UnifiedLessonRequest> {
  @override
  final int typeId = 128;

  @override
  UnifiedLessonRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedLessonRequest(
      id: fields[0] as String,
      studentId: fields[1] as String,
      teacherId: fields[2] as String,
      type: fields[3] as LessonRequestType,
      instrument: fields[4] as String,
      goal: fields[5] as UnifiedLessonGoal,
      experience: fields[6] as UnifiedExperienceLevel,
      message: fields[7] as String?,
      preferredDay: fields[8] as int?,
      preferredTime: fields[9] as String?,
      preferredDuration: fields[10] as int,
      proposals: (fields[11] as List).cast<TimeProposal>(),
      currentRound: fields[12] as int,
      isReturningStudent: fields[13] as bool,
      status: fields[14] as UnifiedRequestStatus,
      createdAt: fields[15] as DateTime,
      confirmedAt: fields[16] as DateTime?,
      cancelledAt: fields[17] as DateTime?,
      rejectionReason: fields[18] as String?,
      suggestedPrice: fields[19] as int?,
      preferredSlots: (fields[20] as List).cast<PreferredTimeSlot>(),
      proposalId: fields[21] as String?,
      academyId: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedLessonRequest obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.teacherId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.instrument)
      ..writeByte(5)
      ..write(obj.goal)
      ..writeByte(6)
      ..write(obj.experience)
      ..writeByte(7)
      ..write(obj.message)
      ..writeByte(8)
      ..write(obj.preferredDay)
      ..writeByte(9)
      ..write(obj.preferredTime)
      ..writeByte(10)
      ..write(obj.preferredDuration)
      ..writeByte(11)
      ..write(obj.proposals)
      ..writeByte(12)
      ..write(obj.currentRound)
      ..writeByte(13)
      ..write(obj.isReturningStudent)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.confirmedAt)
      ..writeByte(17)
      ..write(obj.cancelledAt)
      ..writeByte(18)
      ..write(obj.rejectionReason)
      ..writeByte(19)
      ..write(obj.suggestedPrice)
      ..writeByte(20)
      ..write(obj.preferredSlots)
      ..writeByte(21)
      ..write(obj.proposalId)
      ..writeByte(22)
      ..write(obj.academyId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedLessonRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LessonRequestTypeAdapter extends TypeAdapter<LessonRequestType> {
  @override
  final int typeId = 120;

  @override
  LessonRequestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LessonRequestType.trial;
      case 1:
        return LessonRequestType.regular;
      case 2:
        return LessonRequestType.package;
      default:
        return LessonRequestType.trial;
    }
  }

  @override
  void write(BinaryWriter writer, LessonRequestType obj) {
    switch (obj) {
      case LessonRequestType.trial:
        writer.writeByte(0);
        break;
      case LessonRequestType.regular:
        writer.writeByte(1);
        break;
      case LessonRequestType.package:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonRequestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedLessonGoalAdapter extends TypeAdapter<UnifiedLessonGoal> {
  @override
  final int typeId = 121;

  @override
  UnifiedLessonGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UnifiedLessonGoal.hobby;
      case 1:
        return UnifiedLessonGoal.exam;
      case 2:
        return UnifiedLessonGoal.major;
      case 3:
        return UnifiedLessonGoal.other;
      default:
        return UnifiedLessonGoal.hobby;
    }
  }

  @override
  void write(BinaryWriter writer, UnifiedLessonGoal obj) {
    switch (obj) {
      case UnifiedLessonGoal.hobby:
        writer.writeByte(0);
        break;
      case UnifiedLessonGoal.exam:
        writer.writeByte(1);
        break;
      case UnifiedLessonGoal.major:
        writer.writeByte(2);
        break;
      case UnifiedLessonGoal.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedLessonGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedExperienceLevelAdapter
    extends TypeAdapter<UnifiedExperienceLevel> {
  @override
  final int typeId = 122;

  @override
  UnifiedExperienceLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UnifiedExperienceLevel.beginner;
      case 1:
        return UnifiedExperienceLevel.intermediate;
      case 2:
        return UnifiedExperienceLevel.advanced;
      default:
        return UnifiedExperienceLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, UnifiedExperienceLevel obj) {
    switch (obj) {
      case UnifiedExperienceLevel.beginner:
        writer.writeByte(0);
        break;
      case UnifiedExperienceLevel.intermediate:
        writer.writeByte(1);
        break;
      case UnifiedExperienceLevel.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedExperienceLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedRequestStatusAdapter extends TypeAdapter<UnifiedRequestStatus> {
  @override
  final int typeId = 123;

  @override
  UnifiedRequestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UnifiedRequestStatus.pending;
      case 1:
        return UnifiedRequestStatus.approved;
      case 2:
        return UnifiedRequestStatus.negotiating;
      case 3:
        return UnifiedRequestStatus.timeConfirmed;
      case 4:
        return UnifiedRequestStatus.proposalSent;
      case 5:
        return UnifiedRequestStatus.proposalAccepted;
      case 6:
        return UnifiedRequestStatus.paymentNotified;
      case 7:
        return UnifiedRequestStatus.completed;
      case 8:
        return UnifiedRequestStatus.rejected;
      case 9:
        return UnifiedRequestStatus.cancelled;
      case 10:
        return UnifiedRequestStatus.expired;
      default:
        return UnifiedRequestStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, UnifiedRequestStatus obj) {
    switch (obj) {
      case UnifiedRequestStatus.pending:
        writer.writeByte(0);
        break;
      case UnifiedRequestStatus.approved:
        writer.writeByte(1);
        break;
      case UnifiedRequestStatus.negotiating:
        writer.writeByte(2);
        break;
      case UnifiedRequestStatus.timeConfirmed:
        writer.writeByte(3);
        break;
      case UnifiedRequestStatus.proposalSent:
        writer.writeByte(4);
        break;
      case UnifiedRequestStatus.proposalAccepted:
        writer.writeByte(5);
        break;
      case UnifiedRequestStatus.paymentNotified:
        writer.writeByte(6);
        break;
      case UnifiedRequestStatus.completed:
        writer.writeByte(7);
        break;
      case UnifiedRequestStatus.rejected:
        writer.writeByte(8);
        break;
      case UnifiedRequestStatus.cancelled:
        writer.writeByte(9);
        break;
      case UnifiedRequestStatus.expired:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedRequestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProposerRoleAdapter extends TypeAdapter<ProposerRole> {
  @override
  final int typeId = 124;

  @override
  ProposerRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProposerRole.student;
      case 1:
        return ProposerRole.teacher;
      default:
        return ProposerRole.student;
    }
  }

  @override
  void write(BinaryWriter writer, ProposerRole obj) {
    switch (obj) {
      case ProposerRole.student:
        writer.writeByte(0);
        break;
      case ProposerRole.teacher:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposerRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProposalActionAdapter extends TypeAdapter<ProposalAction> {
  @override
  final int typeId = 125;

  @override
  ProposalAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProposalAction.propose;
      case 1:
        return ProposalAction.accept;
      case 2:
        return ProposalAction.reject;
      case 3:
        return ProposalAction.counterPropose;
      default:
        return ProposalAction.propose;
    }
  }

  @override
  void write(BinaryWriter writer, ProposalAction obj) {
    switch (obj) {
      case ProposalAction.propose:
        writer.writeByte(0);
        break;
      case ProposalAction.accept:
        writer.writeByte(1);
        break;
      case ProposalAction.reject:
        writer.writeByte(2);
        break;
      case ProposalAction.counterPropose:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSlotOption _$TimeSlotOptionFromJson(Map<String, dynamic> json) =>
    TimeSlotOption(
      id: json['id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isSelected: json['is_selected'] as bool? ?? false,
    );

Map<String, dynamic> _$TimeSlotOptionToJson(TimeSlotOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'is_selected': instance.isSelected,
    };

TimeProposal _$TimeProposalFromJson(Map<String, dynamic> json) => TimeProposal(
      id: json['id'] as String,
      proposerId: json['proposer_id'] as String,
      role: $enumDecode(_$ProposerRoleEnumMap, json['role']),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => TimeSlotOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
      action: $enumDecode(_$ProposalActionEnumMap, json['action']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TimeProposalToJson(TimeProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'proposer_id': instance.proposerId,
      'role': _$ProposerRoleEnumMap[instance.role]!,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'message': instance.message,
      'action': _$ProposalActionEnumMap[instance.action]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ProposerRoleEnumMap = {
  ProposerRole.student: 'student',
  ProposerRole.teacher: 'teacher',
};

const _$ProposalActionEnumMap = {
  ProposalAction.propose: 'propose',
  ProposalAction.accept: 'accept',
  ProposalAction.reject: 'reject',
  ProposalAction.counterPropose: 'counterPropose',
};

PreferredTimeSlot _$PreferredTimeSlotFromJson(Map<String, dynamic> json) =>
    PreferredTimeSlot(
      priority: (json['priority'] as num).toInt(),
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      dayOfWeek: (json['day_of_week'] as num?)?.toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );

Map<String, dynamic> _$PreferredTimeSlotToJson(PreferredTimeSlot instance) =>
    <String, dynamic>{
      'priority': instance.priority,
      'date': instance.date?.toIso8601String(),
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };

UnifiedLessonRequest _$UnifiedLessonRequestFromJson(
        Map<String, dynamic> json) =>
    UnifiedLessonRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      type: $enumDecode(_$LessonRequestTypeEnumMap, json['type']),
      instrument: json['instrument'] as String,
      goal: $enumDecode(_$UnifiedLessonGoalEnumMap, json['goal']),
      experience:
          $enumDecode(_$UnifiedExperienceLevelEnumMap, json['experience']),
      message: json['message'] as String?,
      preferredDay: (json['preferred_day'] as num?)?.toInt(),
      preferredTime: json['preferred_time'] as String?,
      preferredDuration: (json['preferred_duration'] as num?)?.toInt() ?? 60,
      proposals: (json['proposals'] as List<dynamic>?)
              ?.map((e) => TimeProposal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentRound: (json['current_round'] as num?)?.toInt() ?? 0,
      isReturningStudent: json['is_returning_student'] as bool? ?? false,
      status:
          $enumDecodeNullable(_$UnifiedRequestStatusEnumMap, json['status']) ??
              UnifiedRequestStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      rejectionReason: json['decline_reason'] as String?,
      suggestedPrice: (json['suggested_price'] as num?)?.toInt(),
      preferredSlots: (json['preferred_slots'] as List<dynamic>?)
              ?.map(
                  (e) => PreferredTimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      proposalId: json['proposal_id'] as String?,
      academyId: json['academy_id'] as String?,
    );

Map<String, dynamic> _$UnifiedLessonRequestToJson(
        UnifiedLessonRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'teacher_id': instance.teacherId,
      'type': _$LessonRequestTypeEnumMap[instance.type]!,
      'instrument': instance.instrument,
      'goal': _$UnifiedLessonGoalEnumMap[instance.goal]!,
      'experience': _$UnifiedExperienceLevelEnumMap[instance.experience]!,
      'message': instance.message,
      'preferred_day': instance.preferredDay,
      'preferred_time': instance.preferredTime,
      'preferred_duration': instance.preferredDuration,
      'proposals': instance.proposals.map((e) => e.toJson()).toList(),
      'current_round': instance.currentRound,
      'is_returning_student': instance.isReturningStudent,
      'status': _$UnifiedRequestStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'decline_reason': instance.rejectionReason,
      'suggested_price': instance.suggestedPrice,
      'preferred_slots':
          instance.preferredSlots.map((e) => e.toJson()).toList(),
      'proposal_id': instance.proposalId,
      'academy_id': instance.academyId,
    };

const _$LessonRequestTypeEnumMap = {
  LessonRequestType.trial: 'trial',
  LessonRequestType.regular: 'regular',
  LessonRequestType.package: 'package',
};

const _$UnifiedLessonGoalEnumMap = {
  UnifiedLessonGoal.hobby: 'hobby',
  UnifiedLessonGoal.exam: 'exam',
  UnifiedLessonGoal.major: 'major',
  UnifiedLessonGoal.other: 'other',
};

const _$UnifiedExperienceLevelEnumMap = {
  UnifiedExperienceLevel.beginner: 'beginner',
  UnifiedExperienceLevel.intermediate: 'intermediate',
  UnifiedExperienceLevel.advanced: 'advanced',
};

const _$UnifiedRequestStatusEnumMap = {
  UnifiedRequestStatus.pending: 'pending',
  UnifiedRequestStatus.approved: 'approved',
  UnifiedRequestStatus.negotiating: 'negotiating',
  UnifiedRequestStatus.timeConfirmed: 'timeConfirmed',
  UnifiedRequestStatus.proposalSent: 'proposalSent',
  UnifiedRequestStatus.proposalAccepted: 'proposalAccepted',
  UnifiedRequestStatus.paymentNotified: 'paymentNotified',
  UnifiedRequestStatus.completed: 'completed',
  UnifiedRequestStatus.rejected: 'rejected',
  UnifiedRequestStatus.cancelled: 'cancelled',
  UnifiedRequestStatus.expired: 'expired',
};
