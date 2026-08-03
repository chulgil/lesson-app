// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_lesson_request.dart';

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
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$TimeSlotOptionToJson(TimeSlotOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'is_selected': instance.isSelected,
      'date': instance.date?.toIso8601String(),
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
  ProposerRole.system: 'system',
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
      createdAt: dateTimeFromJsonOrNow(json['created_at']),
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
      preferredLocationType: json['preferred_location_type'] as String?,
      studentName: json['student_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      academyName: json['academy_name'] as String?,
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
      'preferred_location_type': instance.preferredLocationType,
      'student_name': instance.studentName,
      'teacher_name': instance.teacherName,
      'academy_name': instance.academyName,
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
  UnifiedRequestStatus.subscriptionIssued: 'subscriptionIssued',
  UnifiedRequestStatus.inProgress: 'inProgress',
};
