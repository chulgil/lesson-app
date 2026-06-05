import 'academy_enums.dart';

/// AcademySubscription entity — 학원 귀속 수강권 정책 (작성 시점 스냅샷).
///
/// Spec: docs/specs/web/academy/academy_schedule_authority_spec.md §2.2,
/// teacher_cancellation_policy_spec §2.3, §5.5.
/// BE: backend/app/models/academy_billing.py AcademySubscription.
///
/// 수강권 본체 (Subscription) 와 1:1 (subscription_id UNIQUE FK). 본 entity
/// 는 정책 변수 + 학원 컨텍스트만 보유 — sessions_remaining / fee 등 일반
/// 수강권 필드는 본체 Subscription 에서 조회.
class AcademySubscription {
  AcademySubscription({
    required this.id,
    required this.academyId,
    required this.subscriptionId,
    required this.studentId,
    required this.teacherMemberId,
    required this.ownership,
    required this.createdAt,
    this.cancellationDeadlineHours = 12,
    this.studentCompensationExtraMinutesEnabled = true,
    this.includeExtraMinutesTextOnLateCancel = true,
    this.studentCompensationExtraMinutesMessage,
    this.notifyOwnerOnLateCancel = true,
    this.createdByUserId,
  }) {
    assert(
      cancellationDeadlineHours >= 0 && cancellationDeadlineHours <= 168,
      'cancellationDeadlineHours must be in 0..168 (BE CheckConstraint)',
    );
  }

  final String id;
  final String academyId;

  /// 수강권 본체 FK (subscription_id, UNIQUE).
  /// BE 의 `subscription_id` 와 1:1 — sessions_remaining / fee 등 본체 필드
  /// 는 이 id 로 별도 조회.
  final String subscriptionId;

  /// 학생 (BE: `academy_student_id`). 빠른 조회 + audit 용 denormalization.
  final String studentId;

  final String teacherMemberId;
  final SubscriptionOwnership ownership;

  /// 작성 시점 스냅샷: 정책 결정 마감 시간 (작성 시점 학원 정책 복제).
  /// 0..168 hours (BE CheckConstraint).
  final int cancellationDeadlineHours;

  final bool studentCompensationExtraMinutesEnabled;
  final bool includeExtraMinutesTextOnLateCancel;
  final String? studentCompensationExtraMinutesMessage;
  final bool notifyOwnerOnLateCancel;

  final DateTime createdAt;

  /// 작성자 audit (학원장 또는 강사 user_id). nullable.
  final String? createdByUserId;

  AcademySubscription copyWith({
    String? id,
    String? academyId,
    String? subscriptionId,
    String? studentId,
    String? teacherMemberId,
    SubscriptionOwnership? ownership,
    int? cancellationDeadlineHours,
    bool? studentCompensationExtraMinutesEnabled,
    bool? includeExtraMinutesTextOnLateCancel,
    String? studentCompensationExtraMinutesMessage,
    bool? notifyOwnerOnLateCancel,
    DateTime? createdAt,
    String? createdByUserId,
  }) {
    return AcademySubscription(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      studentId: studentId ?? this.studentId,
      teacherMemberId: teacherMemberId ?? this.teacherMemberId,
      ownership: ownership ?? this.ownership,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      studentCompensationExtraMinutesEnabled:
          studentCompensationExtraMinutesEnabled ??
          this.studentCompensationExtraMinutesEnabled,
      includeExtraMinutesTextOnLateCancel:
          includeExtraMinutesTextOnLateCancel ??
          this.includeExtraMinutesTextOnLateCancel,
      studentCompensationExtraMinutesMessage:
          studentCompensationExtraMinutesMessage ??
          this.studentCompensationExtraMinutesMessage,
      notifyOwnerOnLateCancel:
          notifyOwnerOnLateCancel ?? this.notifyOwnerOnLateCancel,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademySubscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          academyId == other.academyId &&
          subscriptionId == other.subscriptionId &&
          studentId == other.studentId &&
          teacherMemberId == other.teacherMemberId &&
          ownership == other.ownership &&
          cancellationDeadlineHours == other.cancellationDeadlineHours &&
          studentCompensationExtraMinutesEnabled ==
              other.studentCompensationExtraMinutesEnabled &&
          includeExtraMinutesTextOnLateCancel ==
              other.includeExtraMinutesTextOnLateCancel &&
          studentCompensationExtraMinutesMessage ==
              other.studentCompensationExtraMinutesMessage &&
          notifyOwnerOnLateCancel == other.notifyOwnerOnLateCancel &&
          createdAt == other.createdAt &&
          createdByUserId == other.createdByUserId;

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    subscriptionId,
    studentId,
    teacherMemberId,
    ownership,
    cancellationDeadlineHours,
    studentCompensationExtraMinutesEnabled,
    includeExtraMinutesTextOnLateCancel,
    studentCompensationExtraMinutesMessage,
    notifyOwnerOnLateCancel,
    createdAt,
    createdByUserId,
  );
}
