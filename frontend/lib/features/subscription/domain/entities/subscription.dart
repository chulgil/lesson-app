import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

/// Subscription type.
enum SubscriptionType {
  trial, // Trial lesson (free/discounted)

  monthly, // Monthly (period-based)

  package, // Package (count-based, e.g., 8 lessons, 16 lessons)
}

/// Subscription status.
enum SubscriptionStatus {
  active, // Active (usable)

  expiringSoon, // Expiring soon (within 7 days or 2 lessons remaining)

  expired, // Expired

  paused, // Paused
}

/// Billing type (for teacher/academy settings).
enum BillingType {
  perPackage, // Package billing (pay before N lessons)

  monthly, // Monthly billing (fixed day each month)
}

/// Fifth week policy (for monthly subscriptions).
enum FifthWeekPolicy {
  skip, // Skip (no lesson on 5th week)

  bonus, // Give bonus lesson (+1)

  deduct, // Deduct from existing subscription

  optional, // Student choice
}

/// Payment method for subscription.
enum SubscriptionPaymentMethod {
  cash,

  bankTransfer,

  @Deprecated('Card/PG is not part of the current tuition deposit policy.')
  card,

  other,
}

/// Student subscription entity.
@JsonSerializable()
class Subscription {
  final String id;

  final String studentId; // Student ID

  final String membershipId; // Membership ID (FK -> ClassMembership)

  @Deprecated('Use paymentConfirmed instead. Will be removed in future.')
  final String? paymentId; // Legacy: connected payment ID

  // Subscription info
  final SubscriptionType type; // trial, monthly, package

  final int? totalLessons; // Package: total lessons count

  final int usedLessons; // Used lessons count

  final DateTime? startDate; // Start date

  final DateTime? endDate; // End date (for monthly)

  final int amount; // Amount in KRW

  // Status
  final SubscriptionStatus status;

  final int? lessonsPerMonth; // Monthly: lessons included per month (e.g., 4)

  final DateTime createdAt;

  final DateTime? updatedAt;

  // Bonus and billing settings (new fields)
  final int bonusCount; // Bonus lessons (5th week, events, etc.)

  final BillingType? billingType; // Billing type (perPackage, monthly)

  final int? billingDay; // Billing day for monthly (1-31)

  final FifthWeekPolicy? fifthWeekPolicy; // 5th week policy (monthly only)

  final String? bonusReason; // Reason for bonus (e.g., "5주차", "이벤트")

  /// 🆕 Total reschedule allowance (from template)
  final int totalRescheduleAllowance;

  /// 🆕 Used reschedule count
  final int usedRescheduleCount;

  // === Payment info (integrated from legacy Payment entity) ===

  /// Manual deposit confirmed by teacher. false = deposit confirmation pending.
  final bool paymentConfirmed;

  /// Payment method used.
  final SubscriptionPaymentMethod? paymentMethod;

  /// When student made the payment.
  final DateTime? paidAt;

  /// When teacher confirmed the payment.
  final DateTime? paymentConfirmedAt;

  /// Discount amount in KRW.
  final int? discountAmount;

  /// Reason for discount.
  final String? discountReason;

  /// Original amount before discount (amount = after discount).
  final int? originalAmount;

  /// Reschedule deadline hours — changes within this window consume a reschedule credit.
  final int rescheduleDeadlineHours;

  /// Bonus reschedule credits added post-issuance by the teacher (default 0).
  final int bonusRescheduleCount;

  /// Individual cancel deadline override in hours (null = use default policy).
  final int? overrideCancelDeadlineHours;

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
    this.rescheduleDeadlineHours = 12, // 기본값: 12시간
    this.bonusRescheduleCount = 0,
    this.overrideCancelDeadlineHours,
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

  /// Effective reschedule allowance (base + bonus credits added post-issuance).
  int get effectiveRescheduleAllowance =>
      totalRescheduleAllowance + bonusRescheduleCount;

  /// Remaining reschedule count (effective allowance minus used count).
  int get remainingReschedule => effectiveRescheduleAllowance - usedRescheduleCount;

  /// Check if student can reschedule (has remaining allowance).
  bool get canReschedule => remainingReschedule > 0;

  /// Effective cancel deadline hours (override if set, otherwise base policy).
  int get effectiveCancelDeadlineHours =>
      overrideCancelDeadlineHours ?? rescheduleDeadlineHours;

  /// Check if this subscription is pending postpaid deposit:
  /// active, postpaid, and no student payment has been recorded yet.
  bool get isUnpaid =>
      status == SubscriptionStatus.active &&
      !paymentConfirmed &&
      paidAt == null;

  /// Student has reported payment, but teacher has not confirmed the deposit.
  bool get needsPaymentConfirmation =>
      status == SubscriptionStatus.active &&
      !paymentConfirmed &&
      paidAt != null;

  /// Days until expiration.
  int? get daysUntilExpiration => endDate?.difference(DateTime.now()).inDays;

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
    int? bonusRescheduleCount,
    int? overrideCancelDeadlineHours,
    bool clearOverrideCancelDeadlineHours = false,
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
      bonusRescheduleCount: bonusRescheduleCount ?? this.bonusRescheduleCount,
      overrideCancelDeadlineHours: clearOverrideCancelDeadlineHours
          ? null
          : overrideCancelDeadlineHours ?? this.overrideCancelDeadlineHours,
    );
  }

  @override
  String toString() =>
      'Subscription(id: $id, studentId: $studentId, type: $type, status: $status)';
}
