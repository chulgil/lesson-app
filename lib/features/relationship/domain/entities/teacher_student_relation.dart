import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/date_utils.dart';
import 'relationship_status.dart';

part 'teacher_student_relation.g.dart';

/// Subscription-based teacher-student relationship.
///
/// Relationship is defined by subscription status:
/// - trialBooked: Trial lesson booked
/// - active: Valid subscription exists
/// - expired: Subscription expired within 30 days
/// - past: Subscription expired more than 30 days ago
///
/// See: docs/specs/invite/subscription_based_relationship.md
@HiveType(typeId: 90)
@JsonSerializable()
class TeacherStudentRelation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final String studentId;

  /// Relationship status (subscription-based)
  @HiveField(3)
  final RelationshipStatus status;

  /// Active subscription ID (if exists)
  @HiveField(4)
  final String? activeSubscriptionId;

  /// Last subscription expiration date
  @HiveField(5)
  final DateTime? lastSubscriptionExpiredAt;

  /// Expiry grace period end date (lastSubscriptionExpiredAt + 30 days)
  @HiveField(6)
  final DateTime? expiredUntil;

  /// First connection timestamp
  @HiveField(7)
  final DateTime createdAt;

  /// Last status change timestamp
  @HiveField(8)
  final DateTime updatedAt;

  /// Trial booking ID (when status is trialBooked)
  @HiveField(9)
  final String? trialBookingId;

  /// Total lesson count
  @HiveField(10)
  final int totalLessonCount;

  /// Last lesson datetime
  @HiveField(11)
  final DateTime? lastLessonAt;

  /// User who terminated the relationship (if explicitly terminated)
  @HiveField(12)
  final String? terminatedBy;

  /// Termination reason
  @HiveField(13)
  final String? terminationReason;

  /// Whether manually registered (offline student)
  /// If true, status transition rules don't apply (always active)
  @HiveField(14)
  final bool isManuallyRegistered;

  /// Whether app is connected (for manually registered students who later connect)
  @HiveField(15)
  final bool isAppConnected;

  /// App connection timestamp
  @HiveField(16)
  final DateTime? appConnectedAt;

  // ============================================================
  // Previous Schedule Fields (for re-enrollment restoration)
  // ============================================================

  /// Last regular lesson day of week (1=월, 7=일)
  @HiveField(17)
  final int? lastLessonDay;

  /// Last regular lesson time (HH:mm format)
  @HiveField(18)
  final String? lastLessonTime;

  /// Last regular lesson duration in minutes
  @HiveField(19)
  final int? lastLessonDuration;

  /// When the schedule was last recorded
  @HiveField(20)
  final DateTime? lastScheduleRecordedAt;

  TeacherStudentRelation({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.status,
    this.activeSubscriptionId,
    this.lastSubscriptionExpiredAt,
    this.expiredUntil,
    required this.createdAt,
    required this.updatedAt,
    this.trialBookingId,
    this.totalLessonCount = 0,
    this.lastLessonAt,
    this.terminatedBy,
    this.terminationReason,
    this.isManuallyRegistered = false,
    this.isAppConnected = true,
    this.appConnectedAt,
    this.lastLessonDay,
    this.lastLessonTime,
    this.lastLessonDuration,
    this.lastScheduleRecordedAt,
  });

  /// Effective status (manually registered students are always active)
  RelationshipStatus get effectiveStatus {
    if (isManuallyRegistered && !isAppConnected) {
      return RelationshipStatus.active;
    }
    return status;
  }

  /// Whether practice can be shared
  bool canSharePractice({bool practiceShareEnabled = true}) {
    if (!isAppConnected) return false;
    if (status != RelationshipStatus.active) return false;
    if (!practiceShareEnabled) return false;
    return true;
  }

  /// Whether this relationship is expired (within grace period)
  bool get isExpired => status == RelationshipStatus.expired;

  /// Whether this relationship is past (grace period ended)
  bool get isPast => status == RelationshipStatus.past;

  /// Whether subscription is valid
  bool get hasValidSubscription =>
      activeSubscriptionId != null && status == RelationshipStatus.active;

  /// Days until past transition (only valid for expired status)
  int? get daysUntilPast {
    if (status != RelationshipStatus.expired || expiredUntil == null) {
      return null;
    }
    return expiredUntil!.difference(DateTime.now()).inDays;
  }

  /// Days since subscription expired
  int? get daysSinceExpired {
    if (lastSubscriptionExpiredAt == null) return null;
    return DateTime.now().difference(lastSubscriptionExpiredAt!).inDays;
  }

  /// Whether this relationship has a previous schedule that can be restored
  bool get hasPreviousSchedule =>
      lastLessonDay != null && lastLessonTime != null;

  /// Formatted previous schedule label (e.g., "화요일 15:00")
  String? get previousScheduleLabel {
    if (!hasPreviousSchedule) return null;
    return LessonDateUtils.formatScheduleDisplay(
      weekday: lastLessonDay!,
      time: lastLessonTime!,
    );
  }

  TeacherStudentRelation copyWith({
    String? id,
    String? teacherId,
    String? studentId,
    RelationshipStatus? status,
    String? activeSubscriptionId,
    DateTime? lastSubscriptionExpiredAt,
    DateTime? expiredUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? trialBookingId,
    int? totalLessonCount,
    DateTime? lastLessonAt,
    String? terminatedBy,
    String? terminationReason,
    bool? isManuallyRegistered,
    bool? isAppConnected,
    DateTime? appConnectedAt,
    int? lastLessonDay,
    String? lastLessonTime,
    int? lastLessonDuration,
    DateTime? lastScheduleRecordedAt,
  }) {
    return TeacherStudentRelation(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,
      lastSubscriptionExpiredAt:
          lastSubscriptionExpiredAt ?? this.lastSubscriptionExpiredAt,
      expiredUntil: expiredUntil ?? this.expiredUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trialBookingId: trialBookingId ?? this.trialBookingId,
      totalLessonCount: totalLessonCount ?? this.totalLessonCount,
      lastLessonAt: lastLessonAt ?? this.lastLessonAt,
      terminatedBy: terminatedBy ?? this.terminatedBy,
      terminationReason: terminationReason ?? this.terminationReason,
      isManuallyRegistered: isManuallyRegistered ?? this.isManuallyRegistered,
      isAppConnected: isAppConnected ?? this.isAppConnected,
      appConnectedAt: appConnectedAt ?? this.appConnectedAt,
      lastLessonDay: lastLessonDay ?? this.lastLessonDay,
      lastLessonTime: lastLessonTime ?? this.lastLessonTime,
      lastLessonDuration: lastLessonDuration ?? this.lastLessonDuration,
      lastScheduleRecordedAt:
          lastScheduleRecordedAt ?? this.lastScheduleRecordedAt,
    );
  }

  factory TeacherStudentRelation.fromJson(Map<String, dynamic> json) =>
      _$TeacherStudentRelationFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherStudentRelationToJson(this);

  @override
  String toString() {
    return 'TeacherStudentRelation(id: $id, teacherId: $teacherId, '
        'studentId: $studentId, status: $status)';
  }
}
