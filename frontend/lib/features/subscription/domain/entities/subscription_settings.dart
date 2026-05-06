import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings.g.dart';

/// Discount type for bulk purchase.
@HiveType(typeId: 60)
enum DiscountType {
  @HiveField(0)
  discount, // Percentage discount

  @HiveField(1)
  bonusLessons, // Free bonus lessons
}

/// Package discount policy for bulk purchase.
@HiveType(typeId: 61)
@JsonSerializable()
class PackageDiscountPolicy {
  @HiveField(0)
  final int minLessons; // Minimum lessons to qualify (e.g., 10)

  @HiveField(1)
  final DiscountType type; // discount or bonusLessons

  @HiveField(2)
  final int value; // Discount % or bonus lesson count

  @HiveField(3)
  final String? description; // Optional description

  const PackageDiscountPolicy({
    required this.minLessons,
    required this.type,
    required this.value,
    this.description,
  });

  factory PackageDiscountPolicy.fromJson(Map<String, dynamic> json) =>
      _$PackageDiscountPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$PackageDiscountPolicyToJson(this);

  /// Calculate bonus lessons for given purchase count.
  int calculateBonusLessons(int purchasedLessons) {
    if (purchasedLessons >= minLessons && type == DiscountType.bonusLessons) {
      return value;
    }
    return 0;
  }

  /// Calculate discount amount for given price.
  int calculateDiscount(int originalPrice, int purchasedLessons) {
    if (purchasedLessons >= minLessons && type == DiscountType.discount) {
      return (originalPrice * value / 100).round();
    }
    return 0;
  }

  @override
  String toString() =>
      'PackageDiscountPolicy(minLessons: $minLessons, type: $type, value: $value)';
}

/// Subscription settings for teacher or organization.
@HiveType(typeId: 62)
@JsonSerializable()
class SubscriptionSettings extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? teacherId; // For individual teacher

  @HiveField(2)
  final String? organizationId; // For academy/organization

  // Renewal alert settings
  @HiveField(3)
  final int renewalAlertThreshold; // Alert when remaining <= N (default: 1)

  @HiveField(4)
  final int renewalAlertDays; // Alert N days before expiry (default: 7)

  // Bulk purchase policies
  @HiveField(5)
  final List<PackageDiscountPolicy> discountPolicies;

  // Notification settings
  @HiveField(6)
  final bool enablePushNotification; // App push notification

  @HiveField(7)
  final bool enableBadge; // In-app badge

  @HiveField(8)
  final bool notifyParent; // Also notify parent

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? updatedAt;

  SubscriptionSettings({
    required this.id,
    this.teacherId,
    this.organizationId,
    this.renewalAlertThreshold = 1, // Default: alert at 1 lesson remaining
    this.renewalAlertDays = 7, // Default: alert 7 days before expiry
    this.discountPolicies = const [],
    this.enablePushNotification = true,
    this.enableBadge = true,
    this.notifyParent = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSettingsToJson(this);

  /// Get best applicable discount policy for given lesson count.
  PackageDiscountPolicy? getBestPolicy(int lessonCount) {
    if (discountPolicies.isEmpty) return null;

    // Sort by minLessons descending to get the best applicable policy
    final applicable =
        discountPolicies.where((p) => lessonCount >= p.minLessons).toList()
          ..sort((a, b) => b.minLessons.compareTo(a.minLessons));

    return applicable.isNotEmpty ? applicable.first : null;
  }

  /// Calculate total bonus lessons for given purchase.
  int calculateTotalBonus(int purchasedLessons) {
    final policy = getBestPolicy(purchasedLessons);
    if (policy == null) return 0;
    return policy.calculateBonusLessons(purchasedLessons);
  }

  /// Calculate discount amount for given purchase.
  int calculateDiscountAmount(int originalPrice, int purchasedLessons) {
    final policy = getBestPolicy(purchasedLessons);
    if (policy == null) return 0;
    return policy.calculateDiscount(originalPrice, purchasedLessons);
  }

  /// Check if remaining lessons should trigger renewal alert.
  bool shouldAlertForRemainingLessons(int remainingLessons) {
    return remainingLessons <= renewalAlertThreshold;
  }

  /// Check if days until expiration should trigger renewal alert.
  bool shouldAlertForDaysRemaining(int daysRemaining) {
    return daysRemaining <= renewalAlertDays;
  }

  SubscriptionSettings copyWith({
    String? id,
    String? teacherId,
    String? organizationId,
    int? renewalAlertThreshold,
    int? renewalAlertDays,
    List<PackageDiscountPolicy>? discountPolicies,
    bool? enablePushNotification,
    bool? enableBadge,
    bool? notifyParent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionSettings(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      organizationId: organizationId ?? this.organizationId,
      renewalAlertThreshold:
          renewalAlertThreshold ?? this.renewalAlertThreshold,
      renewalAlertDays: renewalAlertDays ?? this.renewalAlertDays,
      discountPolicies: discountPolicies ?? this.discountPolicies,
      enablePushNotification:
          enablePushNotification ?? this.enablePushNotification,
      enableBadge: enableBadge ?? this.enableBadge,
      notifyParent: notifyParent ?? this.notifyParent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create default settings for a teacher.
  factory SubscriptionSettings.defaultForTeacher(String teacherId) {
    return SubscriptionSettings(
      id: 'settings_$teacherId',
      teacherId: teacherId,
      renewalAlertThreshold: 1,
      renewalAlertDays: 7,
      discountPolicies: const [
        // Default: 10+ lessons = 1 bonus
        PackageDiscountPolicy(
          minLessons: 10,
          type: DiscountType.bonusLessons,
          value: 1,
        ),
        // Default: 16+ lessons = 2 bonus
        PackageDiscountPolicy(
          minLessons: 16,
          type: DiscountType.bonusLessons,
          value: 2,
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SubscriptionSettings(id: $id, teacherId: $teacherId, threshold: $renewalAlertThreshold)';
}
