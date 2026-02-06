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

/// Payment method for subscription.
@HiveType(typeId: 99)
enum SubscriptionPaymentMethod {
  @HiveField(0)
  cash,

  @HiveField(1)
  bankTransfer,

  @HiveField(2)
  card,

  @HiveField(3)
  other;

  String get label {
    switch (this) {
      case SubscriptionPaymentMethod.cash:
        return '현금';
      case SubscriptionPaymentMethod.bankTransfer:
        return '계좌이체';
      case SubscriptionPaymentMethod.card:
        return '카드';
      case SubscriptionPaymentMethod.other:
        return '기타';
    }
  }
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

  @Deprecated('Use paymentConfirmed instead. Will be removed in future.')
  @HiveField(3)
  final String? paymentId; // Legacy: connected payment ID

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

  /// 🆕 Total reschedule allowance (from template)
  @HiveField(19)
  final int totalRescheduleAllowance;

  /// 🆕 Used reschedule count
  @HiveField(20)
  final int usedRescheduleCount;

  // === Payment info (integrated from legacy Payment entity) ===

  /// Payment confirmed by teacher. false = unpaid (미수금).
  @HiveField(21)
  final bool paymentConfirmed;

  /// Payment method used.
  @HiveField(22)
  final SubscriptionPaymentMethod? paymentMethod;

  /// When student made the payment.
  @HiveField(23)
  final DateTime? paidAt;

  /// When teacher confirmed the payment.
  @HiveField(24)
  final DateTime? paymentConfirmedAt;

  /// Discount amount in KRW.
  @HiveField(25)
  final int? discountAmount;

  /// Reason for discount.
  @HiveField(26)
  final String? discountReason;

  /// Original amount before discount (amount = after discount).
  @HiveField(27)
  final int? originalAmount;

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
    this.totalRescheduleAllowance = 2, // 기본값: 2회
    this.usedRescheduleCount = 0,
    this.paymentConfirmed = true, // Default: confirmed (existing subscriptions)
    this.paymentMethod,
    this.paidAt,
    this.paymentConfirmedAt,
    this.discountAmount,
    this.discountReason,
    this.originalAmount,
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

  /// 🆕 Remaining reschedule count.
  int get remainingReschedule =>
      totalRescheduleAllowance - usedRescheduleCount;

  /// 🆕 Check if student can reschedule (has remaining allowance).
  bool get canReschedule => remainingReschedule > 0;

  /// Check if this subscription is unpaid (active but not payment confirmed).
  bool get isUnpaid => status == SubscriptionStatus.active && !paymentConfirmed;

  /// Payment status label for display.
  String get paymentStatusLabel => paymentConfirmed ? '결제완료' : '미결제';

  /// Days until expiration.
  int? get daysUntilExpiration =>
      endDate?.difference(DateTime.now()).inDays;

  /// Check if all lessons are used (depleted).
  /// Different from expired - depleted is a positive outcome (goal achieved).
  bool get isDepleted {
    if (remainingLessons != null && remainingLessons! <= 0) {
      return true;
    }
    return false;
  }

  /// Check if renewal needed (D-7 or less, or 1 lesson remaining).
  /// Simplified: single warning state (orange) instead of two-stage.
  bool get isExpiringSoon {
    // Already expired or depleted - not "expiring soon"
    if (status == SubscriptionStatus.expired) return false;
    if (isDepleted) return false;
    if (endDate != null && endDate!.isBefore(DateTime.now())) return false;

    // D-7 or less: needs renewal
    if (daysUntilExpiration != null &&
        daysUntilExpiration! >= 0 &&
        daysUntilExpiration! <= 7) {
      return true;
    }
    // 1 lesson remaining: needs renewal
    if (remainingLessons != null && remainingLessons! == 1) {
      return true;
    }
    return false;
  }

  /// Check if expired by date (time ran out).
  /// Note: This is different from isDepleted (lessons used up).
  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (endDate != null && endDate!.isBefore(DateTime.now())) return true;
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

    // Depleted: show "N회 모두 사용" (positive framing)
    if (isDepleted && total != null) {
      return '$total회 모두 사용';
    }

    // Expired by date with unused lessons: show remaining with "만료됨"
    if (isExpired && remaining != null && remaining > 0) {
      return '$remaining회 미사용 (만료됨)';
    }

    // Build hybrid display: "2/4회 남음 (D-15)"
    final countPart = (remaining != null && total != null)
        ? '$remaining/$total회 남음'
        : '';

    String daysPart = '';
    if (status == SubscriptionStatus.paused) {
      daysPart = '일시정지';
    } else if (isExpired) {
      daysPart = '만료됨';
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
    int? totalRescheduleAllowance,
    int? usedRescheduleCount,
    bool? paymentConfirmed,
    SubscriptionPaymentMethod? paymentMethod,
    DateTime? paidAt,
    DateTime? paymentConfirmedAt,
    int? discountAmount,
    String? discountReason,
    int? originalAmount,
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
      totalRescheduleAllowance:
          totalRescheduleAllowance ?? this.totalRescheduleAllowance,
      usedRescheduleCount: usedRescheduleCount ?? this.usedRescheduleCount,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }

  @override
  String toString() =>
      'Subscription(id: $id, studentId: $studentId, type: $type, status: $status)';
}
