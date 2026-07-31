// Group class entity for group lessons
// TypeId range: 80-86 for group class related types

import 'package:json_annotation/json_annotation.dart';

part 'group_class.g.dart';

/// Group class type
enum GroupClassType {
  regular, // Regular recurring class

  dropIn, // Drop-in class (one-time)
}

/// No-show policy for group classes.
///
/// Wire values mirror the backend SSOT (#239, `app.models.schedule.NoShowPolicy`)
/// one-for-one — the same 4 values drive 1:1 and group no-show handling.
enum NoShowPolicy {
  deductCredit, // Deduct 1 lesson from the subscription

  halfCredit, // Deduct 0.5 lesson

  noDeduction, // No deduction (mercy policy)

  reschedule, // No deduction, converted into a makeup credit
}

/// Group class definition
@JsonSerializable()
class GroupClass {
  final String id;

  final String teacherId;

  final String? organizationId; // Academy ID if applicable

  final String name;

  final String? description;

  final GroupClassType type;

  final int maxCapacity; // Maximum students allowed

  final int? waitlistCapacity; // Max waitlist size (null = unlimited)

  final int durationMinutes;

  final int bookingDeadlineMinutes; // How long before class to allow booking

  // How long before class to allow cancellation
  final int cancelDeadlineMinutes;

  final NoShowPolicy noShowPolicy;

  final int? maxNoShowCount; // Max no-shows before warning/action

  final List<int>? repeatDaysOfWeek; // 1-7 for Mon-Sun (for regular classes)

  final String? repeatTimeOfDay; // HH:mm format (for regular classes)

  final String? instrument; // e.g., 'violin', 'piano'

  final int? pricePerSession; // Price per session (optional)

  final bool isActive;

  final DateTime createdAt;

  final DateTime? updatedAt;

  GroupClass({
    required this.id,
    required this.teacherId,
    this.organizationId,
    required this.name,
    this.description,
    required this.type,
    required this.maxCapacity,
    this.waitlistCapacity,
    required this.durationMinutes,
    this.bookingDeadlineMinutes = 60, // Default 1 hour
    this.cancelDeadlineMinutes = 1440, // Default 24 hours
    this.noShowPolicy = NoShowPolicy.deductCredit,
    this.maxNoShowCount,
    this.repeatDaysOfWeek,
    this.repeatTimeOfDay,
    this.instrument,
    this.pricePerSession,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory GroupClass.fromJson(Map<String, dynamic> json) =>
      _$GroupClassFromJson(json);

  Map<String, dynamic> toJson() => _$GroupClassToJson(this);

  GroupClass copyWith({
    String? id,
    String? teacherId,
    String? organizationId,
    String? name,
    String? description,
    GroupClassType? type,
    int? maxCapacity,
    int? waitlistCapacity,
    int? durationMinutes,
    int? bookingDeadlineMinutes,
    int? cancelDeadlineMinutes,
    NoShowPolicy? noShowPolicy,
    int? maxNoShowCount,
    List<int>? repeatDaysOfWeek,
    String? repeatTimeOfDay,
    String? instrument,
    int? pricePerSession,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupClass(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      waitlistCapacity: waitlistCapacity ?? this.waitlistCapacity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bookingDeadlineMinutes:
          bookingDeadlineMinutes ?? this.bookingDeadlineMinutes,
      cancelDeadlineMinutes:
          cancelDeadlineMinutes ?? this.cancelDeadlineMinutes,
      noShowPolicy: noShowPolicy ?? this.noShowPolicy,
      maxNoShowCount: maxNoShowCount ?? this.maxNoShowCount,
      repeatDaysOfWeek: repeatDaysOfWeek ?? this.repeatDaysOfWeek,
      repeatTimeOfDay: repeatTimeOfDay ?? this.repeatTimeOfDay,
      instrument: instrument ?? this.instrument,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if waitlist is allowed
  bool get allowsWaitlist => waitlistCapacity == null || waitlistCapacity! > 0;

  /// Get formatted schedule for regular classes
  String get scheduleText {
    if (type != GroupClassType.regular ||
        repeatDaysOfWeek == null ||
        repeatTimeOfDay == null) {
      return '';
    }

    final dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final days = repeatDaysOfWeek!.map((d) => dayNames[d]).join(', ');
    return '$days $repeatTimeOfDay';
  }
}
