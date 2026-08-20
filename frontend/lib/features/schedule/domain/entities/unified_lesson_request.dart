import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_converters.dart';

part 'unified_lesson_request.g.dart';

/// Type of lesson being requested
enum LessonRequestType { trial, regular, package }

/// Goal for the lesson
enum UnifiedLessonGoal { hobby, exam, major, other }

/// Experience level of the student
enum UnifiedExperienceLevel { beginner, intermediate, advanced }

/// Status of the unified lesson request
enum UnifiedRequestStatus {
  pending,
  approved,
  negotiating,
  timeConfirmed,
  proposalSent,
  proposalAccepted,
  paymentNotified,
  completed,
  rejected,
  cancelled,
  expired,

  // Phase 2: 수강권 발행 (NEW)
  subscriptionIssued,

  // Phase 3: 레슨 진행 (NEW)
  inProgress;

  bool get isActive => [
    UnifiedRequestStatus.pending,
    UnifiedRequestStatus.approved,
    UnifiedRequestStatus.negotiating,
    UnifiedRequestStatus.timeConfirmed,
    UnifiedRequestStatus.proposalSent,
    UnifiedRequestStatus.proposalAccepted,
    UnifiedRequestStatus.paymentNotified,
    UnifiedRequestStatus.subscriptionIssued,
    UnifiedRequestStatus.inProgress,
  ].contains(this);

  bool get isTerminal => [
    UnifiedRequestStatus.completed,
    UnifiedRequestStatus.rejected,
    UnifiedRequestStatus.cancelled,
    UnifiedRequestStatus.expired,
  ].contains(this);
}

/// Lifecycle phase for chapter-based UI.
enum RequestPhase {
  request, // Phase 1: 레슨 신청 → 입금
  subscription, // Phase 2: 수강권 발행
  lessons, // Phase 3: 레슨 진행
  completed, // 전체 완료
  terminal, // 거절/취소/만료
}

/// Who proposed the time slot.
/// [system] is used for batch-generated events (e.g. scheduleChangeExpired — #692).
enum ProposerRole { student, teacher, system }

/// Action type in a time proposal
enum ProposalAction { propose, accept, reject, counterPropose }

/// A time slot option within a proposal
@JsonSerializable()
class TimeSlotOption {
  final String id;

  final int dayOfWeek; // 0=Mon...6=Sun

  final String startTime; // HH:mm

  final String endTime; // HH:mm

  final bool isSelected;

  final DateTime? date;

  TimeSlotOption({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isSelected = false,
    this.date,
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
    DateTime? date,
  }) {
    return TimeSlotOption(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSelected: isSelected ?? this.isSelected,
      date: date ?? this.date,
    );
  }
}

/// A negotiation turn (proposal or counter-proposal)
@JsonSerializable()
class TimeProposal {
  final String id;

  final String proposerId;

  final ProposerRole role;

  final List<TimeSlotOption> slots;

  final String? message;

  final ProposalAction action;

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
@JsonSerializable()
class PreferredTimeSlot {
  final int priority;

  /// Specific date for trial/per-session lessons.
  final DateTime? date;

  /// Day of week for regular lessons (0=Mon...6=Sun).
  final int? dayOfWeek;

  final String startTime;

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
}

/// Unified lesson request — replaces separate trial/regular/returning flows
@JsonSerializable()
class UnifiedLessonRequest {
  final String id;

  final String studentId;

  final String teacherId;

  // Lesson info
  final LessonRequestType type;

  final String instrument;

  final UnifiedLessonGoal goal;

  final UnifiedExperienceLevel experience;

  /// J15b — the cohort (반) this request enrolls into, when the student applied
  /// from a teacher's open-class section. Null for ordinary 1:1 requests; the
  /// roster assignment happens when the teacher confirms a group proposal.
  final String? groupClassId;

  final String? message;

  // Time negotiation
  final int? preferredDay; // 0=Mon...6=Sun

  final String? preferredTime; // HH:mm

  final int preferredDuration; // minutes

  final List<TimeProposal> proposals;

  final int currentRound;

  // Returning student info
  final bool isReturningStudent;

  // Status
  final UnifiedRequestStatus status;

  // #706 — BE UnifiedLessonRequestResponse 는 created_at 이
  // `datetime | None = None`. strict DateTime.parse throw 방지.
  @JsonKey(fromJson: dateTimeFromJsonOrNow)
  final DateTime createdAt;

  final DateTime? confirmedAt;

  final DateTime? cancelledAt;

  @JsonKey(name: 'decline_reason')
  final String? rejectionReason;

  // Price reference
  final int? suggestedPrice;

  // Preferred time slots (v2.0 — max 3 preferences)
  final List<PreferredTimeSlot> preferredSlots;

  // Linked subscription proposal (v3.0 — proposal integration)
  final String? proposalId;

  // v4.0: Academy association
  final String? academyId;

  // v5.0: 학생 희망 레슨 장소 (수강권 발급 시 디폴트로 전달)
  final String?
  preferredLocationType; // "studentHome" | "academyRoom" | "teacherStudio" | "externalPlace" | "online"

  // v6.0: Display names — populated by BE in remote mode; null in mock
  // (name-map fallback resolves display). Additive, backward-compatible.
  final String? studentName;

  final String? teacherName;

  final String? academyName;

  UnifiedLessonRequest({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.type,
    required this.instrument,
    required this.goal,
    required this.experience,
    this.groupClassId,
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
    this.academyId,
    this.preferredLocationType,
    this.studentName,
    this.teacherName,
    this.academyName,
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
      UnifiedRequestStatus.pending, // withdraw approval before student acts
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
      UnifiedRequestStatus.subscriptionIssued,
      UnifiedRequestStatus.cancelled,
    },
  };

  /// Whether the request can transition to [target] status.
  bool canTransitionTo(UnifiedRequestStatus target) {
    return _transitions[status]?.contains(target) ?? false;
  }

  /// Whether the student is waiting for the teacher to send a proposal.
  bool get isWaitingForProposal => status == UnifiedRequestStatus.timeConfirmed;

  /// Whether a proposal has been received (awaiting student action).
  bool get isProposalReceived => status == UnifiedRequestStatus.proposalSent;

  /// Whether payment is pending (accepted but not yet confirmed by teacher).
  bool get isPaymentPending =>
      status == UnifiedRequestStatus.proposalAccepted ||
      status == UnifiedRequestStatus.paymentNotified;

  /// Whether a subscription proposal is linked.
  bool get hasProposal => proposalId != null;

  /// Whether this request belongs to an academy.
  bool get isAcademy => academyId != null;

  /// Whether the request is expired by date (7 days from creation).
  bool get isExpiredByDate => DateTime.now().difference(createdAt).inDays >= 7;

  /// Last message from the most recent event (for list preview).
  String? get lastMessage => null; // TODO: Populate from RequestEvent list

  /// Current lifecycle phase for chapter-based UI.
  RequestPhase get currentPhase {
    return switch (status) {
      UnifiedRequestStatus.pending ||
      UnifiedRequestStatus.negotiating ||
      UnifiedRequestStatus.approved => RequestPhase.request,
      // Phase 2 (Subscription): timeConfirmed → proposal → payment → issue
      UnifiedRequestStatus.timeConfirmed ||
      UnifiedRequestStatus.proposalSent ||
      UnifiedRequestStatus.proposalAccepted ||
      UnifiedRequestStatus.paymentNotified ||
      UnifiedRequestStatus.subscriptionIssued => RequestPhase.subscription,
      UnifiedRequestStatus.inProgress => RequestPhase.lessons,
      UnifiedRequestStatus.completed => RequestPhase.completed,
      UnifiedRequestStatus.rejected ||
      UnifiedRequestStatus.cancelled ||
      UnifiedRequestStatus.expired => RequestPhase.terminal,
    };
  }

  /// Whether it's the teacher's turn based on last proposal.
  bool get isTeacherTurn {
    if (status == UnifiedRequestStatus.pending) return true;
    if (status == UnifiedRequestStatus.timeConfirmed) return true;
    if (status == UnifiedRequestStatus.negotiating && proposals.isNotEmpty) {
      return proposals.last.role == ProposerRole.student;
    }
    return false;
  }

  /// Whether teacher needs to act now.
  bool get isTeacherActionRequired {
    switch (status) {
      case UnifiedRequestStatus.pending:
      case UnifiedRequestStatus.timeConfirmed:
      case UnifiedRequestStatus.paymentNotified:
      case UnifiedRequestStatus.inProgress:
        return true;
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.negotiating:
        return isTeacherTurn;
      default:
        return false;
    }
  }

  /// Whether student needs to act now.
  bool get isStudentActionRequired {
    switch (status) {
      case UnifiedRequestStatus.proposalSent:
      case UnifiedRequestStatus.proposalAccepted:
      case UnifiedRequestStatus.inProgress:
        return true;
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.negotiating:
        return !isTeacherTurn;
      default:
        return false;
    }
  }

  /// Color key: 'action' (paperAccent) or 'wait' (inkTertiary).
  String get studentActionColorKey =>
      isStudentActionRequired ? 'action' : 'wait';

  /// Color key: 'action' (paperAccent) or 'wait' (inkTertiary).
  String get teacherActionColorKey =>
      isTeacherActionRequired ? 'action' : 'wait';

  UnifiedLessonRequest copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    LessonRequestType? type,
    String? instrument,
    UnifiedLessonGoal? goal,
    UnifiedExperienceLevel? experience,
    String? groupClassId,
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
    String? academyId,
    String? preferredLocationType,
    String? studentName,
    String? teacherName,
    String? academyName,
  }) {
    return UnifiedLessonRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      type: type ?? this.type,
      instrument: instrument ?? this.instrument,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      groupClassId: groupClassId ?? this.groupClassId,
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
      academyId: academyId ?? this.academyId,
      preferredLocationType:
          preferredLocationType ?? this.preferredLocationType,
      studentName: studentName ?? this.studentName,
      teacherName: teacherName ?? this.teacherName,
      academyName: academyName ?? this.academyName,
    );
  }

  @override
  String toString() =>
      'UnifiedLessonRequest(id: $id, type: $type, status: $status, '
      'student: $studentId, teacher: $teacherId)';
}
