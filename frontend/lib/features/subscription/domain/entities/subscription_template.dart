import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_template.g.dart';

/// Owner type for subscription template.
@HiveType(typeId: 95)
enum SubscriptionTemplateOwnerType {
  @HiveField(0)
  teacher, // Individual teacher

  @HiveField(1)
  academy, // Academy/organization
}

/// Subscription template - defines a subscription product.
///
/// Teachers and academies create templates to define their subscription offerings.
/// When a student purchases, a Subscription is created from this template.
@HiveType(typeId: 96)
@JsonSerializable()
class SubscriptionTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  /// Owner ID (teacherId or academyId)
  @HiveField(1)
  final String ownerId;

  /// Owner type (teacher or academy)
  @HiveField(2)
  final SubscriptionTemplateOwnerType ownerType;

  /// Template name (e.g., "8회권", "기본 패키지")
  @HiveField(3)
  final String name;

  /// Total number of lessons in this package
  @HiveField(4)
  final int totalLessons;

  /// Lesson duration in minutes (30, 45, 50, 60)
  @HiveField(5)
  final int lessonDurationMinutes;

  /// Validity period in days after activation (e.g., 90 days)
  @HiveField(6)
  final int validityDays;

  /// Price in KRW
  @HiveField(7)
  final int price;

  /// Whether this template is active and available for purchase
  @HiveField(8)
  final bool isActive;

  /// Display order (lower = shown first)
  @HiveField(9)
  final int displayOrder;

  /// Optional description
  @HiveField(10)
  final String? description;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  /// 🆕 Reschedule allowance count (default: 2)
  /// Students can reschedule lessons up to this many times.
  /// When 0, students cannot reschedule by themselves.
  @HiveField(13)
  final int rescheduleAllowance;

  /// 🆕 자동 제안 대상 여부 (default: true)
  /// true: 체험레슨 완료 또는 수강권 만료 시 자동으로 제안됨
  /// false: 선생님이 직접 제안할 때만 사용 가능
  @HiveField(14)
  final bool isAutoProposalEnabled;

  SubscriptionTemplate({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.name,
    required this.totalLessons,
    required this.lessonDurationMinutes,
    required this.validityDays,
    required this.price,
    this.isActive = true,
    this.displayOrder = 0,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.rescheduleAllowance = 2, // 기본값: 2회
    this.isAutoProposalEnabled = true, // 기본값: 자동 제안 활성화
  });

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionTemplateToJson(this);

  /// Price per lesson
  int get pricePerLesson => totalLessons > 0 ? price ~/ totalLessons : 0;

  /// Formatted price (e.g., "40만원")
  String get formattedPrice {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$man만원';
      }
      return '$man만 $remainder원';
    }
    return '$price원';
  }

  /// Formatted price per lesson
  String get formattedPricePerLesson {
    final ppl = pricePerLesson;
    if (ppl >= 10000) {
      final man = ppl ~/ 10000;
      final remainder = ppl % 10000;
      if (remainder == 0) {
        return '$man만원';
      }
      return '$man만 $remainder원';
    }
    return '$ppl원';
  }

  /// Formatted validity period
  String get formattedValidity {
    if (validityDays >= 30) {
      final months = validityDays ~/ 30;
      return '$months개월';
    }
    return '$validityDays일';
  }

  /// Summary text (e.g., "8회 · 50분 · 40만원")
  String get summaryText {
    return '$totalLessons회 · $lessonDurationMinutes분 · $formattedPrice';
  }

  /// Display label (e.g., "8회권 (50분)")
  String get displayLabel => '$name ($lessonDurationMinutes분)';

  /// Owner type display label
  String get ownerTypeLabel {
    switch (ownerType) {
      case SubscriptionTemplateOwnerType.teacher:
        return '개인';
      case SubscriptionTemplateOwnerType.academy:
        return '학원';
    }
  }

  SubscriptionTemplate copyWith({
    String? id,
    String? ownerId,
    SubscriptionTemplateOwnerType? ownerType,
    String? name,
    int? totalLessons,
    int? lessonDurationMinutes,
    int? validityDays,
    int? price,
    bool? isActive,
    int? displayOrder,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? rescheduleAllowance,
    bool? isAutoProposalEnabled,
  }) {
    return SubscriptionTemplate(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerType: ownerType ?? this.ownerType,
      name: name ?? this.name,
      totalLessons: totalLessons ?? this.totalLessons,
      lessonDurationMinutes:
          lessonDurationMinutes ?? this.lessonDurationMinutes,
      validityDays: validityDays ?? this.validityDays,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rescheduleAllowance: rescheduleAllowance ?? this.rescheduleAllowance,
      isAutoProposalEnabled:
          isAutoProposalEnabled ?? this.isAutoProposalEnabled,
    );
  }

  @override
  String toString() =>
      'SubscriptionTemplate(id: $id, name: $name, totalLessons: $totalLessons)';
}
