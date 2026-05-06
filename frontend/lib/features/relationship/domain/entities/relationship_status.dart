/// Subscription-based teacher-student relationship status.
///
/// Relationship is defined by subscription status, not mutual follow.
/// See: docs/specs/invite/subscription_based_relationship.md
enum RelationshipStatus {
  /// Trial lesson booked (before subscription)
  trialBooked,

  /// Active - subscription valid (regular lessons in progress)
  active,

  /// Expired - subscription expired within 30 days
  expired,

  /// Past - subscription expired more than 30 days ago
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
    return this == RelationshipStatus.expired ||
        this == RelationshipStatus.past;
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
