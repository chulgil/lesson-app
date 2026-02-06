import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_confirmation_card.g.dart';

/// Type of schedule confirmation card based on scenario.
@HiveType(typeId: 100)
enum ScheduleCardType {
  /// New student after trial lesson - suggest trial time
  @HiveField(0)
  afterTrial,

  /// Re-enrollment - suggest previous schedule
  @HiveField(1)
  reEnrollment,

  /// Additional instrument - no previous schedule, must select
  @HiveField(2)
  additionalInstrument,
}

/// Extension for ScheduleCardType
extension ScheduleCardTypeExtension on ScheduleCardType {
  String get label {
    switch (this) {
      case ScheduleCardType.afterTrial:
        return '체험 후 등록';
      case ScheduleCardType.reEnrollment:
        return '재등록';
      case ScheduleCardType.additionalInstrument:
        return '추가 악기';
    }
  }

  String get suggestionText {
    switch (this) {
      case ScheduleCardType.afterTrial:
        return '체험 레슨 시간으로 예약할까요?';
      case ScheduleCardType.reEnrollment:
        return '이전 스케줄로 예약할까요?';
      case ScheduleCardType.additionalInstrument:
        return '레슨 시간을 선택해주세요';
    }
  }

  /// Whether this card type has a suggested time
  bool get hasSuggestedTime =>
      this == ScheduleCardType.afterTrial ||
      this == ScheduleCardType.reEnrollment;
}

/// Status of schedule confirmation card.
@HiveType(typeId: 101)
enum ScheduleCardStatus {
  /// Waiting for student to confirm
  @HiveField(0)
  pending,

  /// Student confirmed the suggested time
  @HiveField(1)
  confirmed,

  /// Student selected a different time
  @HiveField(2)
  changedTime,

  /// Card dismissed/expired
  @HiveField(3)
  dismissed,
}

/// Extension for ScheduleCardStatus
extension ScheduleCardStatusExtension on ScheduleCardStatus {
  String get label {
    switch (this) {
      case ScheduleCardStatus.pending:
        return '확인 대기';
      case ScheduleCardStatus.confirmed:
        return '확정됨';
      case ScheduleCardStatus.changedTime:
        return '시간 변경됨';
      case ScheduleCardStatus.dismissed:
        return '닫힘';
    }
  }

  bool get isActive => this == ScheduleCardStatus.pending;
  bool get isResolved =>
      this == ScheduleCardStatus.confirmed ||
      this == ScheduleCardStatus.changedTime;
}

/// Schedule confirmation card shown to student after subscription issuance.
///
/// This card prompts the student to confirm their lesson schedule after
/// a subscription has been issued. Depending on the scenario, it may
/// suggest a previous schedule or trial lesson time.
@HiveType(typeId: 102)
@JsonSerializable()
class ScheduleConfirmationCard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  @HiveField(3)
  final String teacherName;

  @HiveField(4)
  final String? instrument;

  /// Related subscription ID
  @HiveField(5)
  final String subscriptionId;

  /// Suggested lesson day (1=Mon, 7=Sun), null if no suggestion
  @HiveField(6)
  final int? suggestedDay;

  /// Suggested lesson time (e.g., "15:00"), null if no suggestion
  @HiveField(7)
  final String? suggestedTime;

  /// Lesson duration in minutes
  @HiveField(8)
  final int? lessonDuration;

  /// Card type based on scenario
  @HiveField(9)
  final ScheduleCardType cardType;

  /// Current status
  @HiveField(10)
  final ScheduleCardStatus status;

  /// When the card was created
  @HiveField(11)
  final DateTime createdAt;

  /// When the student responded
  @HiveField(12)
  final DateTime? respondedAt;

  /// Subscription details for display
  @HiveField(13)
  final int? totalLessons;

  /// Related lesson request ID (for re-enrollment)
  @HiveField(14)
  final String? lessonRequestId;

  ScheduleConfirmationCard({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.teacherName,
    this.instrument,
    required this.subscriptionId,
    this.suggestedDay,
    this.suggestedTime,
    this.lessonDuration,
    required this.cardType,
    this.status = ScheduleCardStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.totalLessons,
    this.lessonRequestId,
  });

  factory ScheduleConfirmationCard.fromJson(Map<String, dynamic> json) =>
      _$ScheduleConfirmationCardFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleConfirmationCardToJson(this);

  /// Whether the card has a suggested schedule
  bool get hasSuggestedSchedule =>
      suggestedDay != null && suggestedTime != null;

  /// Whether the card is still actionable
  bool get isActionable => status == ScheduleCardStatus.pending;

  /// Formatted suggested schedule display
  String? get formattedSuggestedSchedule {
    if (!hasSuggestedSchedule) return null;

    final dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[suggestedDay!];
    final duration = lessonDuration != null ? ' ($lessonDuration분)' : '';

    return '매주 $dayName요일 $suggestedTime$duration';
  }

  /// Create a copy with updated fields
  ScheduleConfirmationCard copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? teacherName,
    String? instrument,
    String? subscriptionId,
    int? suggestedDay,
    String? suggestedTime,
    int? lessonDuration,
    ScheduleCardType? cardType,
    ScheduleCardStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    int? totalLessons,
    String? lessonRequestId,
  }) {
    return ScheduleConfirmationCard(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      instrument: instrument ?? this.instrument,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      suggestedDay: suggestedDay ?? this.suggestedDay,
      suggestedTime: suggestedTime ?? this.suggestedTime,
      lessonDuration: lessonDuration ?? this.lessonDuration,
      cardType: cardType ?? this.cardType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      totalLessons: totalLessons ?? this.totalLessons,
      lessonRequestId: lessonRequestId ?? this.lessonRequestId,
    );
  }

  @override
  String toString() {
    return 'ScheduleConfirmationCard(id: $id, studentId: $studentId, '
        'teacherId: $teacherId, cardType: $cardType, status: $status)';
  }
}
