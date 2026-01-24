import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

/// Subscription type.
@HiveType(typeId: 55)
enum SubscriptionType {
  @HiveField(0)
  trial, // Trial lesson (free/discounted)

  @HiveField(1)
  monthly, // Monthly (period-based)

  @HiveField(2)
  package, // Package (count-based, e.g., 8 lessons, 16 lessons)
}

/// Subscription status.
@HiveType(typeId: 56)
enum SubscriptionStatus {
  @HiveField(0)
  active, // Active (usable)

  @HiveField(1)
  expiringSoon, // Expiring soon (within 7 days or 2 lessons remaining)

  @HiveField(2)
  expired, // Expired

  @HiveField(3)
  paused, // Paused
}

/// Student subscription entity.
@HiveType(typeId: 57)
@JsonSerializable()
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId; // Student ID

  @HiveField(2)
  final String membershipId; // Membership ID (FK -> ClassMembership)

  @HiveField(3)
  final String? paymentId; // Connected payment ID (optional)

  // Subscription info
  @HiveField(4)
  final SubscriptionType type; // trial, monthly, package

  @HiveField(5)
  final int? totalLessons; // Package: total lessons count

  @HiveField(6)
  final int usedLessons; // Used lessons count

  @HiveField(7)
  final DateTime? startDate; // Start date

  @HiveField(8)
  final DateTime? endDate; // End date (for monthly)

  @HiveField(9)
  final int amount; // Amount in KRW

  // Status
  @HiveField(10)
  final SubscriptionStatus status;

  @HiveField(13)
  final int? lessonsPerMonth; // Monthly: lessons included per month (e.g., 4)

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  Subscription({
    required this.id,
    required this.studentId,
    required this.membershipId,
    this.paymentId,
    required this.type,
    this.totalLessons,
    this.lessonsPerMonth,
    this.usedLessons = 0,
    this.startDate,
    this.endDate,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  /// Total lessons for display (package: totalLessons, monthly: lessonsPerMonth).
  int? get totalLessonsForDisplay =>
      type == SubscriptionType.package ? totalLessons : lessonsPerMonth;

  /// Remaining lessons count (hybrid: package or monthly).
  int? get remainingLessons {
    if (type == SubscriptionType.package && totalLessons != null) {
      return totalLessons! - usedLessons;
    }
    if (type == SubscriptionType.monthly && lessonsPerMonth != null) {
      return lessonsPerMonth! - usedLessons;
    }
    if (type == SubscriptionType.trial) {
      return 1 - usedLessons;
    }
    return null;
  }

  /// Days until expiration.
  int? get daysUntilExpiration =>
      endDate?.difference(DateTime.now()).inDays;

  /// Check if expiring soon (7 days or 2 lessons remaining).
  bool get isExpiringSoon {
    if (daysUntilExpiration != null && daysUntilExpiration! <= 7) {
      return true;
    }
    if (remainingLessons != null && remainingLessons! <= 2) {
      return true;
    }
    return false;
  }

  /// Check if expired.
  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (endDate != null && endDate!.isBefore(DateTime.now())) return true;
    if (remainingLessons != null && remainingLessons! <= 0) return true;
    return false;
  }

  /// Usage percentage (hybrid).
  double? get usagePercentage {
    final total = totalLessonsForDisplay;
    if (total != null && total > 0) {
      return (usedLessons / total) * 100;
    }
    return null;
  }

  /// Type display label in Korean.
  String get typeLabel {
    switch (type) {
      case SubscriptionType.trial:
        return '체험';
      case SubscriptionType.monthly:
        return lessonsPerMonth != null ? '월정액 (${lessonsPerMonth}회)' : '월정액';
      case SubscriptionType.package:
        return '${totalLessons ?? 0}회권';
    }
  }

  /// Status display label in Korean.
  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return '이용중';
      case SubscriptionStatus.expiringSoon:
        return '만료 임박';
      case SubscriptionStatus.expired:
        return '만료됨';
      case SubscriptionStatus.paused:
        return '일시정지';
    }
  }

  /// Summary text for display (hybrid: count + days).
  String get summaryText {
    if (type == SubscriptionType.trial) {
      return usedLessons > 0 ? '체험 완료' : '체험중';
    }

    final remaining = remainingLessons;
    final total = totalLessonsForDisplay;
    final days = daysUntilExpiration;

    // Build hybrid display: "2/4회 남음 (D-15)"
    final countPart = (remaining != null && total != null)
        ? '$remaining/${total}회 남음'
        : '';

    String daysPart = '';
    if (status == SubscriptionStatus.paused) {
      daysPart = '일시정지';
    } else if (status == SubscriptionStatus.expired) {
      daysPart = '만료됨';
    } else if (remaining != null && remaining <= 0) {
      daysPart = '소진됨';
    } else if (days != null && days > 0) {
      daysPart = 'D-$days';
    } else if (days != null && days <= 0) {
      daysPart = '만료됨';
    }

    if (countPart.isNotEmpty && daysPart.isNotEmpty) {
      return '$countPart ($daysPart)';
    }
    return countPart.isNotEmpty ? countPart : daysPart;
  }

  Subscription copyWith({
    String? id,
    String? studentId,
    String? membershipId,
    String? paymentId,
    SubscriptionType? type,
    int? totalLessons,
    int? lessonsPerMonth,
    int? usedLessons,
    DateTime? startDate,
    DateTime? endDate,
    int? amount,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      membershipId: membershipId ?? this.membershipId,
      paymentId: paymentId ?? this.paymentId,
      type: type ?? this.type,
      totalLessons: totalLessons ?? this.totalLessons,
      lessonsPerMonth: lessonsPerMonth ?? this.lessonsPerMonth,
      usedLessons: usedLessons ?? this.usedLessons,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Subscription(id: $id, studentId: $studentId, type: $type, status: $status)';
}
