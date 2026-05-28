import 'academy_enums.dart';

/// AcademySubscription entity — 학원 귀속 수강권
class AcademySubscription {
  final String id;
  final String academyId;
  final String studentId;
  final String teacherMemberId;
  final SubscriptionOwnership ownership;
  final int cancellationDeadlineHours;
  final bool studentCompensationExtraMinutesEnabled;
  final bool includeExtraMinutesTextOnLateCancel;
  final String? studentCompensationExtraMinutesMessage;
  final bool notifyOwnerOnLateCancel;
  final DateTime createdAt;

  const AcademySubscription({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.teacherMemberId,
    required this.ownership,
    this.cancellationDeadlineHours = 12,
    this.studentCompensationExtraMinutesEnabled = true,
    this.includeExtraMinutesTextOnLateCancel = true,
    this.studentCompensationExtraMinutesMessage,
    this.notifyOwnerOnLateCancel = true,
    required this.createdAt,
  });

  AcademySubscription copyWith({
    String? id,
    String? academyId,
    String? studentId,
    String? teacherMemberId,
    SubscriptionOwnership? ownership,
    int? cancellationDeadlineHours,
    bool? studentCompensationExtraMinutesEnabled,
    bool? includeExtraMinutesTextOnLateCancel,
    String? studentCompensationExtraMinutesMessage,
    bool? notifyOwnerOnLateCancel,
    DateTime? createdAt,
  }) {
    return AcademySubscription(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademySubscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          academyId == other.academyId &&
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
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      academyId.hashCode ^
      studentId.hashCode ^
      teacherMemberId.hashCode ^
      ownership.hashCode ^
      cancellationDeadlineHours.hashCode ^
      studentCompensationExtraMinutesEnabled.hashCode ^
      includeExtraMinutesTextOnLateCancel.hashCode ^
      studentCompensationExtraMinutesMessage.hashCode ^
      notifyOwnerOnLateCancel.hashCode ^
      createdAt.hashCode;
}
