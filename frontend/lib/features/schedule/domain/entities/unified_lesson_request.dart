import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/l10n/app_strings.dart';

part 'unified_lesson_request.g.dart';

/// Type of lesson being requested
@HiveType(typeId: 120)
enum LessonRequestType {
  @HiveField(0)
  trial,

  @HiveField(1)
  regular,

  @HiveField(2)
  package;

  String get label {
    switch (this) {
      case LessonRequestType.trial:
        return '체험레슨';
      case LessonRequestType.regular:
        return '정규레슨';
      case LessonRequestType.package:
        return '회차권';
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
  expired,

  // Phase 2: 수강권 발행 (NEW)
  @HiveField(11)
  subscriptionIssued,

  // Phase 3: 레슨 진행 (NEW)
  @HiveField(12)
  inProgress;

  String get label {
    switch (this) {
      case UnifiedRequestStatus.pending:
        return AppStrings.statusPending;
      case UnifiedRequestStatus.approved:
        return AppStrings.statusApproved;
      case UnifiedRequestStatus.negotiating:
        return AppStrings.statusNegotiatingShort;
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.statusTimeConfirmed;
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.statusProposalSent;
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.statusProposalAccepted;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.statusPaymentDone;
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
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
  request,       // Phase 1: 레슨 신청 → 입금
  subscription,  // Phase 2: 수강권 발행
  lessons,       // Phase 3: 레슨 진행
  completed,     // 전체 완료
  terminal,      // 거절/취소/만료
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

  @HiveField(5)
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

  /// Day of week label (Korean)
  String get dayLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayOfWeek.clamp(0, 6)];
  }

  /// Display label: "4/5(토) 14:00 ~ 15:00" or "토 14:00 ~ 15:00"
  String get displayLabel {
    if (date != null) {
      return '${date!.month}/${date!.day}($dayLabel) $startTime ~ $endTime';
    }
    return '$dayLabel $startTime ~ $endTime';
  }
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
  /// date있으면: "3/29(토) 14:00 ~ 15:00"
  /// dayOfWeek만: "토 14:00 ~ 15:00"
  String get displayLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    if (date != null) {
      final d = date!;
      final dayLabel = days[d.weekday - 1];
      return '${d.month}/${d.day}($dayLabel) $startTime ~ $endTime';
    }
    if (dayOfWeek != null) {
      return '${days[dayOfWeek!.clamp(0, 6)]} $startTime ~ $endTime';
    }
    return '$startTime ~ $endTime';
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
  @JsonKey(name: 'decline_reason')
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

  // v4.0: Academy association
  @HiveField(22)
  final String? academyId;

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
    this.academyId,
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

  /// Whether this request belongs to an academy.
  bool get isAcademy => academyId != null;

  /// Whether the request is expired by date (7 days from creation).
  bool get isExpiredByDate =>
      DateTime.now().difference(createdAt).inDays >= 7;

  /// Last message from the most recent event (for list preview).
  String? get lastMessage => null; // TODO: Populate from RequestEvent list

  /// Status chip label for the list item.
  String get statusChipLabel {
    switch (status) {
      case UnifiedRequestStatus.pending:
        return AppStrings.statusPending;
      case UnifiedRequestStatus.approved:
        return AppStrings.statusApproved;
      case UnifiedRequestStatus.negotiating:
        return AppStrings.statusNegotiating(currentRound);
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.statusTimeConfirmed;
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.statusProposalSent;
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.statusProposalAccepted;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.statusPaymentDone;
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
    }
  }

  /// Current lifecycle phase for chapter-based UI.
  RequestPhase get currentPhase {
    return switch (status) {
      UnifiedRequestStatus.pending ||
      UnifiedRequestStatus.negotiating ||
      UnifiedRequestStatus.approved =>
        RequestPhase.request,
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
      UnifiedRequestStatus.expired =>
        RequestPhase.terminal,
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

  /// Action-oriented chip label for teacher's list view.
  /// Shows what teacher should do next instead of just status.
  String get teacherActionLabel {
    switch (status) {
      case UnifiedRequestStatus.pending:
        return AppStrings.actionRequired;        // 확인 필요
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.negotiating:
        return isTeacherTurn
            ? AppStrings.responseRequired          // 응답 필요
            : AppStrings.responseWaiting;          // 응답 대기
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.proposalNeeded;          // 제안 작성
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.teacherWaitingAccept;
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.teacherWaitingPayment;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.teacherVerifyPayment;
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
    }
  }

  /// Action-oriented chip label for student's list view.
  /// Shows what student should do next or current status from student's perspective.
  String get studentActionLabel {
    switch (status) {
      case UnifiedRequestStatus.pending:
        return AppStrings.studentRequestSent;      // 요청 전송됨
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.negotiating:
        return isTeacherTurn
            ? AppStrings.studentResponseWaiting    // 선생님 응답 대기
            : AppStrings.studentResponseRequired;  // 응답 필요
      case UnifiedRequestStatus.timeConfirmed:
        return AppStrings.studentWaitingProposal;  // 수강권 대기
      case UnifiedRequestStatus.proposalSent:
        return AppStrings.studentProposalArrived;  // 수강권 도착
      case UnifiedRequestStatus.proposalAccepted:
        return AppStrings.studentPaymentRequired;
      case UnifiedRequestStatus.paymentNotified:
        return AppStrings.studentPaymentWaiting;   // 입금 확인 중
      case UnifiedRequestStatus.completed:
        return AppStrings.statusCompleted;
      case UnifiedRequestStatus.rejected:
        return AppStrings.statusRejected;
      case UnifiedRequestStatus.cancelled:
        return AppStrings.statusCancelled;
      case UnifiedRequestStatus.expired:
        return AppStrings.statusExpiredFull;
      case UnifiedRequestStatus.subscriptionIssued:
        return AppStrings.statusSubscriptionIssued;
      case UnifiedRequestStatus.inProgress:
        return AppStrings.statusInProgress;
    }
  }

  /// Color key for student action chip.
  /// Color key: 'action' (내 차례), 'wait' (대기/종료)
  String get studentActionColorKey {
    switch (status) {
      case UnifiedRequestStatus.proposalSent:
      case UnifiedRequestStatus.proposalAccepted:
      case UnifiedRequestStatus.inProgress:
        return 'action';
      case UnifiedRequestStatus.negotiating:
        return isTeacherTurn ? 'wait' : 'action';
      case UnifiedRequestStatus.pending:
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.timeConfirmed:
      case UnifiedRequestStatus.paymentNotified:
      case UnifiedRequestStatus.subscriptionIssued:
      case UnifiedRequestStatus.completed:
      case UnifiedRequestStatus.rejected:
      case UnifiedRequestStatus.cancelled:
      case UnifiedRequestStatus.expired:
        return 'wait';
    }
  }

  /// Color key for action chip: 'action', 'wait', 'success', 'error', 'warning'.
  /// Color key: 'action' (내 차례), 'wait' (대기/종료)
  String get teacherActionColorKey {
    switch (status) {
      case UnifiedRequestStatus.pending:
      case UnifiedRequestStatus.timeConfirmed:
      case UnifiedRequestStatus.paymentNotified:
      case UnifiedRequestStatus.inProgress:
        return 'action';
      case UnifiedRequestStatus.negotiating:
        return isTeacherTurn ? 'action' : 'wait';
      case UnifiedRequestStatus.approved:
      case UnifiedRequestStatus.proposalSent:
      case UnifiedRequestStatus.proposalAccepted:
      case UnifiedRequestStatus.subscriptionIssued:
      case UnifiedRequestStatus.completed:
      case UnifiedRequestStatus.rejected:
      case UnifiedRequestStatus.cancelled:
      case UnifiedRequestStatus.expired:
        return 'wait';
    }
  }

  /// Type display label (재수강 > 정규 priority).
  String get typeDisplayLabel {
    if (isReturningStudent && type == LessonRequestType.regular) {
      return '재수강';
    }
    return type.label;
  }

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
    String? academyId,
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
      academyId: academyId ?? this.academyId,
    );
  }

  @override
  String toString() =>
      'UnifiedLessonRequest(id: $id, type: $type, status: $status, '
      'student: $studentId, teacher: $teacherId)';
}
