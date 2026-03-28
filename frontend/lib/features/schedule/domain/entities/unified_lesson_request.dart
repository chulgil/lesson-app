import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unified_lesson_request.g.dart';

/// Type of lesson being requested
@HiveType(typeId: 120)
enum LessonRequestType {
  @HiveField(0)
  trial,

  @HiveField(1)
  regular;

  String get label {
    switch (this) {
      case LessonRequestType.trial:
        return '체험레슨';
      case LessonRequestType.regular:
        return '정규레슨';
    }
  }
}

/// Goal for the lesson
@HiveType(typeId: 121)
enum UnifiedLessonGoal {
  @HiveField(0)
  hobby,

  @HiveField(1)
  exam,

  @HiveField(2)
  major,

  @HiveField(3)
  other;

  String get label {
    switch (this) {
      case UnifiedLessonGoal.hobby:
        return '취미';
      case UnifiedLessonGoal.exam:
        return '입시';
      case UnifiedLessonGoal.major:
        return '전공';
      case UnifiedLessonGoal.other:
        return '기타';
    }
  }
}

/// Experience level of the student
@HiveType(typeId: 122)
enum UnifiedExperienceLevel {
  @HiveField(0)
  beginner,

  @HiveField(1)
  intermediate,

  @HiveField(2)
  advanced;

  String get label {
    switch (this) {
      case UnifiedExperienceLevel.beginner:
        return '초급';
      case UnifiedExperienceLevel.intermediate:
        return '중급';
      case UnifiedExperienceLevel.advanced:
        return '고급';
    }
  }
}

/// Status of the unified lesson request
@HiveType(typeId: 123)
enum UnifiedRequestStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  approved,

  @HiveField(2)
  negotiating,

  @HiveField(3)
  timeConfirmed,

  @HiveField(4)
  proposalSent,

  @HiveField(5)
  proposalAccepted,

  @HiveField(6)
  paymentNotified,

  @HiveField(7)
  completed,

  @HiveField(8)
  rejected,

  @HiveField(9)
  cancelled,

  @HiveField(10)
  expired;

  String get label {
    switch (this) {
      case UnifiedRequestStatus.pending:
        return '확인 대기';
      case UnifiedRequestStatus.approved:
        return '승인됨';
      case UnifiedRequestStatus.negotiating:
        return '시간 협상 중';
      case UnifiedRequestStatus.timeConfirmed:
        return '시간 확정';
      case UnifiedRequestStatus.proposalSent:
        return '수강권 제안됨';
      case UnifiedRequestStatus.proposalAccepted:
        return '수강권 수락됨';
      case UnifiedRequestStatus.paymentNotified:
        return '결제 완료 알림';
      case UnifiedRequestStatus.completed:
        return '발급 완료';
      case UnifiedRequestStatus.rejected:
        return '거절됨';
      case UnifiedRequestStatus.cancelled:
        return '취소됨';
      case UnifiedRequestStatus.expired:
        return '만료됨';
    }
  }

  bool get isActive => [
        UnifiedRequestStatus.pending,
        UnifiedRequestStatus.approved,
        UnifiedRequestStatus.negotiating,
        UnifiedRequestStatus.timeConfirmed,
        UnifiedRequestStatus.proposalSent,
        UnifiedRequestStatus.proposalAccepted,
        UnifiedRequestStatus.paymentNotified,
      ].contains(this);

  bool get isTerminal => [
        UnifiedRequestStatus.completed,
        UnifiedRequestStatus.rejected,
        UnifiedRequestStatus.cancelled,
        UnifiedRequestStatus.expired,
      ].contains(this);
}

/// Who proposed the time slot
@HiveType(typeId: 124)
enum ProposerRole {
  @HiveField(0)
  student,

  @HiveField(1)
  teacher;
}

/// Action type in a time proposal
@HiveType(typeId: 125)
enum ProposalAction {
  @HiveField(0)
  propose,

  @HiveField(1)
  accept,

  @HiveField(2)
  reject,

  @HiveField(3)
  counterPropose;
}

/// A time slot option within a proposal
@HiveType(typeId: 126)
@JsonSerializable()
class TimeSlotOption extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int dayOfWeek; // 0=Mon...6=Sun

  @HiveField(2)
  final String startTime; // HH:mm

  @HiveField(3)
  final String endTime; // HH:mm

  @HiveField(4)
  final bool isSelected;

  TimeSlotOption({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isSelected = false,
  });

  factory TimeSlotOption.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotOptionFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotOptionToJson(this);

  TimeSlotOption copyWith({
    String? id,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isSelected,
  }) {
    return TimeSlotOption(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Day of week label (Korean)
  String get dayLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayOfWeek.clamp(0, 6)];
  }

  /// Display label: "토요일 14:00 ~ 15:00"
  String get displayLabel => '$dayLabel요일 $startTime ~ $endTime';
}

/// A negotiation turn (proposal or counter-proposal)
@HiveType(typeId: 127)
@JsonSerializable()
class TimeProposal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String proposerId;

  @HiveField(2)
  final ProposerRole role;

  @HiveField(3)
  final List<TimeSlotOption> slots;

  @HiveField(4)
  final String? message;

  @HiveField(5)
  final ProposalAction action;

  @HiveField(6)
  final DateTime createdAt;

  TimeProposal({
    required this.id,
    required this.proposerId,
    required this.role,
    required this.slots,
    this.message,
    required this.action,
    required this.createdAt,
  });

  factory TimeProposal.fromJson(Map<String, dynamic> json) =>
      _$TimeProposalFromJson(json);

  Map<String, dynamic> toJson() => _$TimeProposalToJson(this);
}

/// Preferred time slot with priority ranking (1=highest, 3=lowest).
@HiveType(typeId: 129)
@JsonSerializable()
class PreferredTimeSlot {
  @HiveField(0)
  final int priority;

  /// Specific date for trial/per-session lessons.
  @HiveField(1)
  final DateTime? date;

  /// Day of week for regular lessons (0=Mon...6=Sun).
  @HiveField(2)
  final int? dayOfWeek;

  @HiveField(3)
  final String startTime;

  @HiveField(4)
  final String endTime;

  const PreferredTimeSlot({
    required this.priority,
    this.date,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory PreferredTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$PreferredTimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$PreferredTimeSlotToJson(this);

  /// Display label for the selection list.
  String get displayLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    if (date != null) {
      final d = date!;
      final dayLabel = days[d.weekday - 1];
      return '${d.month}/${d.day}($dayLabel) $startTime';
    }
    if (dayOfWeek != null) {
      return '매주 ${days[dayOfWeek!.clamp(0, 6)]}요일 $startTime';
    }
    return startTime;
  }
}

/// Unified lesson request — replaces separate trial/regular/returning flows
@HiveType(typeId: 128)
@JsonSerializable()
class UnifiedLessonRequest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  // Lesson info
  @HiveField(3)
  final LessonRequestType type;

  @HiveField(4)
  final String instrument;

  @HiveField(5)
  final UnifiedLessonGoal goal;

  @HiveField(6)
  final UnifiedExperienceLevel experience;

  @HiveField(7)
  final String? message;

  // Time negotiation
  @HiveField(8)
  final int? preferredDay; // 0=Mon...6=Sun

  @HiveField(9)
  final String? preferredTime; // HH:mm

  @HiveField(10)
  final int preferredDuration; // minutes

  @HiveField(11)
  final List<TimeProposal> proposals;

  @HiveField(12)
  final int currentRound;

  // Returning student info
  @HiveField(13)
  final bool isReturningStudent;

  // Status
  @HiveField(14)
  final UnifiedRequestStatus status;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime? confirmedAt;

  @HiveField(17)
  final DateTime? cancelledAt;

  @HiveField(18)
  final String? rejectionReason;

  // Price reference
  @HiveField(19)
  final int? suggestedPrice;

  // Preferred time slots (v2.0 — max 3 preferences)
  @HiveField(20)
  final List<PreferredTimeSlot> preferredSlots;

  // Linked subscription proposal (v3.0 — proposal integration)
  @HiveField(21)
  final String? proposalId;

  UnifiedLessonRequest({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.type,
    required this.instrument,
    required this.goal,
    required this.experience,
    this.message,
    this.preferredDay,
    this.preferredTime,
    this.preferredDuration = 60,
    this.proposals = const [],
    this.currentRound = 0,
    this.isReturningStudent = false,
    this.status = UnifiedRequestStatus.pending,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.rejectionReason,
    this.suggestedPrice,
    this.preferredSlots = const [],
    this.proposalId,
  });

  factory UnifiedLessonRequest.fromJson(Map<String, dynamic> json) =>
      _$UnifiedLessonRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedLessonRequestToJson(this);

  /// Whether the request is still active
  bool get isActive => status.isActive;

  /// Whether the request is in a terminal state
  bool get isTerminal => status.isTerminal;

  /// Valid state transitions for the request lifecycle.
  static const _transitions = <UnifiedRequestStatus, Set<UnifiedRequestStatus>>{
    UnifiedRequestStatus.pending: {
      UnifiedRequestStatus.approved,
      UnifiedRequestStatus.rejected,
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.approved: {
      UnifiedRequestStatus.negotiating,
      UnifiedRequestStatus.timeConfirmed,
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.negotiating: {
      UnifiedRequestStatus.timeConfirmed,
      UnifiedRequestStatus.expired,
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.timeConfirmed: {
      UnifiedRequestStatus.proposalSent,
      UnifiedRequestStatus.completed, // trial-free path
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.proposalSent: {
      UnifiedRequestStatus.proposalAccepted,
      UnifiedRequestStatus.rejected,
      UnifiedRequestStatus.expired,
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.proposalAccepted: {
      UnifiedRequestStatus.paymentNotified,
      UnifiedRequestStatus.cancelled,
    },
    UnifiedRequestStatus.paymentNotified: {
      UnifiedRequestStatus.completed,
      UnifiedRequestStatus.cancelled,
    },
  };

  /// Whether the request can transition to [target] status.
  bool canTransitionTo(UnifiedRequestStatus target) {
    return _transitions[status]?.contains(target) ?? false;
  }

  /// Whether the student is waiting for the teacher to send a proposal.
  bool get isWaitingForProposal =>
      status == UnifiedRequestStatus.timeConfirmed;

  /// Whether a proposal has been received (awaiting student action).
  bool get isProposalReceived =>
      status == UnifiedRequestStatus.proposalSent;

  /// Whether payment is pending (accepted but not yet confirmed by teacher).
  bool get isPaymentPending =>
      status == UnifiedRequestStatus.proposalAccepted ||
      status == UnifiedRequestStatus.paymentNotified;

  /// Whether a subscription proposal is linked.
  bool get hasProposal => proposalId != null;

  /// Preferred day label (Korean)
  String? get preferredDayLabel {
    if (preferredDay == null) return null;
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[preferredDay!.clamp(0, 6)]}요일';
  }

  UnifiedLessonRequest copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    LessonRequestType? type,
    String? instrument,
    UnifiedLessonGoal? goal,
    UnifiedExperienceLevel? experience,
    String? message,
    int? preferredDay,
    String? preferredTime,
    int? preferredDuration,
    List<TimeProposal>? proposals,
    int? currentRound,
    bool? isReturningStudent,
    UnifiedRequestStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? rejectionReason,
    int? suggestedPrice,
    List<PreferredTimeSlot>? preferredSlots,
    String? proposalId,
  }) {
    return UnifiedLessonRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      type: type ?? this.type,
      instrument: instrument ?? this.instrument,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      message: message ?? this.message,
      preferredDay: preferredDay ?? this.preferredDay,
      preferredTime: preferredTime ?? this.preferredTime,
      preferredDuration: preferredDuration ?? this.preferredDuration,
      proposals: proposals ?? this.proposals,
      currentRound: currentRound ?? this.currentRound,
      isReturningStudent: isReturningStudent ?? this.isReturningStudent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      preferredSlots: preferredSlots ?? this.preferredSlots,
      proposalId: proposalId ?? this.proposalId,
    );
  }

  @override
  String toString() =>
      'UnifiedLessonRequest(id: $id, type: $type, status: $status, '
      'student: $studentId, teacher: $teacherId)';
}
