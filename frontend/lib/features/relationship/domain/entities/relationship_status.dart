import 'package:hive/hive.dart';

part 'relationship_status.g.dart';

/// Subscription-based teacher-student relationship status.
///
/// Relationship is defined by subscription status, not mutual follow.
/// See: docs/specs/invite/subscription_based_relationship.md
@HiveType(typeId: 91)
enum RelationshipStatus {
  /// Trial lesson booked (before subscription)
  @HiveField(0)
  trialBooked,

  /// Active - subscription valid (regular lessons in progress)
  @HiveField(1)
  active,

  /// Expired - subscription expired within 30 days
  @HiveField(2)
  expired,

  /// Past - subscription expired more than 30 days ago
  @HiveField(3)
  past,
}

/// Extension methods for RelationshipStatus
extension RelationshipStatusExtension on RelationshipStatus {
  /// Display name in Korean
  String get displayName {
    switch (this) {
      case RelationshipStatus.trialBooked:
        return '체험 예정';
      case RelationshipStatus.active:
        return '수강 중';
      case RelationshipStatus.expired:
        return '수강권 만료';
      case RelationshipStatus.past:
        return '이전 레슨';
    }
  }

  /// Whether this status allows lesson booking
  bool get canBookLesson {
    return this == RelationshipStatus.active;
  }

  /// Whether this status allows lesson request
  bool get canRequestLesson {
    return this == RelationshipStatus.expired || this == RelationshipStatus.past;
  }

  /// Whether this status allows practice sharing
  bool get canSharePractice {
    return this == RelationshipStatus.active;
  }

  /// Whether this is an active relationship (not past)
  bool get isActiveRelationship {
    return this != RelationshipStatus.past;
  }
}
