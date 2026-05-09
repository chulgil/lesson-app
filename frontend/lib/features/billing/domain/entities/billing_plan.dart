// Billing plan entity matching BE AppBillingPlan API response.

import 'package:json_annotation/json_annotation.dart';

part 'billing_plan.g.dart';

/// Available app subscription plan tiers.
enum BillingPlanType {
  free,
  @JsonValue('trial_pro')
  trialPro,
  pro,
  studio,
  lifetime,
}

/// Feature access flags per plan.
@JsonSerializable()
class BillingFeatures {
  final bool aiNotes;
  final bool recording;
  final bool parentPortal;
  final bool practiceStats;
  final bool multiTeacher;
  final bool customBranding;
  final bool analyticsReport;

  const BillingFeatures({
    required this.aiNotes,
    required this.recording,
    required this.parentPortal,
    required this.practiceStats,
    required this.multiTeacher,
    required this.customBranding,
    required this.analyticsReport,
  });

  factory BillingFeatures.fromJson(Map<String, dynamic> json) =>
      _$BillingFeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$BillingFeaturesToJson(this);

  static const free = BillingFeatures(
    aiNotes: false,
    recording: false,
    parentPortal: false,
    practiceStats: false,
    multiTeacher: false,
    customBranding: false,
    analyticsReport: false,
  );
}

/// Current billing status for the teacher.
@JsonSerializable()
class BillingStatus {
  final String plan;
  final bool isActive;
  final int? studentLimit;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final int? daysRemaining;
  final Map<String, bool> features;

  const BillingStatus({
    required this.plan,
    required this.isActive,
    this.studentLimit,
    this.expiresAt,
    this.trialEndsAt,
    this.daysRemaining,
    required this.features,
  });

  factory BillingStatus.fromJson(Map<String, dynamic> json) =>
      _$BillingStatusFromJson(json);

  Map<String, dynamic> toJson() => _$BillingStatusToJson(this);

  BillingPlanType get planType {
    switch (plan) {
      case 'trial_pro':
        return BillingPlanType.trialPro;
      case 'pro':
        return BillingPlanType.pro;
      case 'studio':
        return BillingPlanType.studio;
      case 'lifetime':
        return BillingPlanType.lifetime;
      default:
        return BillingPlanType.free;
    }
  }

  bool get isFree => planType == BillingPlanType.free;
  bool get isTrial => planType == BillingPlanType.trialPro;
  bool get isPaid =>
      planType == BillingPlanType.pro ||
      planType == BillingPlanType.studio ||
      planType == BillingPlanType.lifetime;

  bool hasFeature(String feature) => features[feature] ?? false;

  static const defaultFree = BillingStatus(
    plan: 'free',
    isActive: true,
    studentLimit: 5,
    features: {
      'ai_notes': false,
      'recording': false,
      'parent_portal': false,
      'practice_stats': false,
      'multi_teacher': false,
      'custom_branding': false,
      'analytics_report': false,
    },
  );
}

/// IAP product info from the store.
@JsonSerializable()
class BillingProduct {
  final String productId;
  final String plan;
  final String description;

  const BillingProduct({
    required this.productId,
    required this.plan,
    required this.description,
  });

  factory BillingProduct.fromJson(Map<String, dynamic> json) =>
      _$BillingProductFromJson(json);

  Map<String, dynamic> toJson() => _$BillingProductToJson(this);
}
