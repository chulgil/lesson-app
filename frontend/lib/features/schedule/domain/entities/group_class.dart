// Group class entity for group lessons
// TypeId range: 80-86 for group class related types

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_class.g.dart';

/// Group class type
@HiveType(typeId: 80)
enum GroupClassType {
  @HiveField(0)
  regular, // Regular recurring class

  @HiveField(1)
  dropIn, // Drop-in class (one-time)
}

/// No-show policy for group classes
@HiveType(typeId: 86)
enum NoShowPolicy {
  @HiveField(0)
  deduct, // Deduct lesson from subscription

  @HiveField(1)
  noDeduct, // No deduction (mercy policy)
}

/// Group class definition
@HiveType(typeId: 81)
@JsonSerializable()
class GroupClass extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final String? organizationId; // Academy ID if applicable

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final GroupClassType type;

  @HiveField(6)
  final int maxCapacity; // Maximum students allowed

  @HiveField(7)
  final int? waitlistCapacity; // Max waitlist size (null = unlimited)

  @HiveField(8)
  final int durationMinutes;

  @HiveField(9)
  final int bookingDeadlineMinutes; // How long before class to allow booking

  @HiveField(10)
  final int cancelDeadlineMinutes; // How long before class to allow cancellation

  @HiveField(11)
  final NoShowPolicy noShowPolicy;

  @HiveField(12)
  final int? maxNoShowCount; // Max no-shows before warning/action

  @HiveField(13)
  final List<int>? repeatDaysOfWeek; // 1-7 for Mon-Sun (for regular classes)

  @HiveField(14)
  final String? repeatTimeOfDay; // HH:mm format (for regular classes)

  @HiveField(15)
  final String? instrument; // e.g., 'violin', 'piano'

  @HiveField(16)
  final int? pricePerSession; // Price per session (optional)

  @HiveField(17)
  final bool isActive;

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
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
    this.noShowPolicy = NoShowPolicy.deduct,
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
