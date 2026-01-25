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

/// Billing type (for teacher/academy settings).
@HiveType(typeId: 58)
enum BillingType {
  @HiveField(0)
  perPackage, // Package billing (pay before N lessons)

  @HiveField(1)
  monthly, // Monthly billing (fixed day each month)
}

/// Fifth week policy (for monthly subscriptions).
@HiveType(typeId: 59)
enum FifthWeekPolicy {
  @HiveField(0)
  skip, // Skip (no lesson on 5th week)

  @HiveField(1)
  bonus, // Give bonus lesson (+1)

  @HiveField(2)
  deduct, // Deduct from existing subscription

  @HiveField(3)
  optional, // Student choice
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

  // Bonus and billing settings (new fields)
  @HiveField(14)
  final int bonusCount; // Bonus lessons (5th week, events, etc.)

  @HiveField(15)
  final BillingType? billingType; // Billing type (perPackage, monthly)

  @HiveField(16)
  final int? billingDay; // Billing day for monthly (1-31)

  @HiveField(17)
  final FifthWeekPolicy? fifthWeekPolicy; // 5th week policy (monthly only)

  @HiveField(18)
  final String? bonusReason; // Reason for bonus (e.g., "5주차", "이벤트")

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
    this.bonusCount = 0,
    this.billingType,
    this.billingDay,
    this.fifthWeekPolicy,
    this.bonusReason,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  /// Total lessons for display (package: totalLessons, monthly: lessonsPerMonth + bonus).
  int? get totalLessonsForDisplay {
    final base =
        type == SubscriptionType.package ? totalLessons : lessonsPerMonth;
    if (base == null) return null;
    return base + bonusCount;
  }

  /// Base lessons without bonus (for display breakdown).
  int? get baseLessons =>
      type == SubscriptionType.package ? totalLessons : lessonsPerMonth;

  /// Remaining lessons count (hybrid: package or monthly + bonus).
  int? get remainingLessons {
    if (type == SubscriptionType.package && totalLessons != null) {
      return totalLessons! + bonusCount - usedLessons;
    }
    if (type == SubscriptionType.monthly && lessonsPerMonth != null) {
      return lessonsPerMonth! + bonusCount - usedLessons;
    }
    if (type == SubscriptionType.trial) {
      return 1 - usedLessons;
    }
    return null;
  }

  /// Check if has bonus lessons.
  bool get hasBonus => bonusCount > 0;

  /// Days until expiration.
  int? get daysUntilExpiration =>
      endDate?.difference(DateTime.now()).inDays;

  /// Check if expiring soon (7 days or 1 lesson remaining).
  /// Returns false for already expired subscriptions.
  /// Note: Threshold is configurable per teacher/academy (default: 1).
  bool get isExpiringSoon {
    // Already expired - not "expiring soon"
    if (status == SubscriptionStatus.expired) return false;
    if (endDate != null && endDate!.isBefore(DateTime.now())) return false;

    if (daysUntilExpiration != null &&
        daysUntilExpiration! >= 0 &&
        daysUntilExpiration! <= 7) {
      return true;
    }
    if (remainingLessons != null &&
        remainingLessons! > 0 &&
        remainingLessons! <= 1) {
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
        return lessonsPerMonth != null ? '월정액 ($lessonsPerMonth회)' : '월정액';
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
        ? '$remaining/$total회 남음'
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

  /// Bonus display text (e.g., "🎁 보너스 +1회 (5주차)").
  String? get bonusText {
    if (bonusCount <= 0) return null;
    final reason = bonusReason ?? '보너스';
    return '🎁 +$bonusCount회 ($reason)';
  }

  /// Detailed breakdown text for display.
  String get detailText {
    if (type == SubscriptionType.trial) {
      return amount > 0 ? '체험 레슨 (${_formatAmount(amount)})' : '무료 체험 레슨';
    }

    final base = baseLessons;
    final buffer = StringBuffer();

    if (type == SubscriptionType.monthly) {
      buffer.write('기본: ${base ?? 0}회');
    } else {
      buffer.write('${base ?? 0}회권 중 $usedLessons회 사용');
    }

    if (bonusCount > 0) {
      buffer.write('\n보너스: +$bonusCount회');
      if (bonusReason != null) {
        buffer.write(' ($bonusReason)');
      }
    }

    return buffer.toString();
  }

  /// Format amount in Korean won.
  String _formatAmount(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '$amount원';
  }

  /// Billing type display label in Korean.
  String? get billingTypeLabel {
    if (billingType == null) return null;
    switch (billingType!) {
      case BillingType.perPackage:
        return '회차 결제';
      case BillingType.monthly:
        return billingDay != null ? '월정액 (매월 $billingDay일)' : '월정액';
    }
  }

  /// Fifth week policy display label in Korean.
  String? get fifthWeekPolicyLabel {
    if (fifthWeekPolicy == null) return null;
    switch (fifthWeekPolicy!) {
      case FifthWeekPolicy.skip:
        return '휴강';
      case FifthWeekPolicy.bonus:
        return '보너스 지급';
      case FifthWeekPolicy.deduct:
        return '기존에서 차감';
      case FifthWeekPolicy.optional:
        return '학생 선택';
    }
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
    int? bonusCount,
    BillingType? billingType,
    int? billingDay,
    FifthWeekPolicy? fifthWeekPolicy,
    String? bonusReason,
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
      bonusCount: bonusCount ?? this.bonusCount,
      billingType: billingType ?? this.billingType,
      billingDay: billingDay ?? this.billingDay,
      fifthWeekPolicy: fifthWeekPolicy ?? this.fifthWeekPolicy,
      bonusReason: bonusReason ?? this.bonusReason,
    );
  }

  @override
  String toString() =>
      'Subscription(id: $id, studentId: $studentId, type: $type, status: $status)';
}
