// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingFeatures _$BillingFeaturesFromJson(Map<String, dynamic> json) =>
    BillingFeatures(
      aiNotes: json['ai_notes'] as bool,
      recording: json['recording'] as bool,
      parentPortal: json['parent_portal'] as bool,
      practiceStats: json['practice_stats'] as bool,
      multiTeacher: json['multi_teacher'] as bool,
      customBranding: json['custom_branding'] as bool,
      analyticsReport: json['analytics_report'] as bool,
    );

Map<String, dynamic> _$BillingFeaturesToJson(BillingFeatures instance) =>
    <String, dynamic>{
      'ai_notes': instance.aiNotes,
      'recording': instance.recording,
      'parent_portal': instance.parentPortal,
      'practice_stats': instance.practiceStats,
      'multi_teacher': instance.multiTeacher,
      'custom_branding': instance.customBranding,
      'analytics_report': instance.analyticsReport,
    };

BillingStatus _$BillingStatusFromJson(Map<String, dynamic> json) =>
    BillingStatus(
      plan: json['plan'] as String,
      isActive: json['is_active'] as bool,
      studentLimit: (json['student_limit'] as num?)?.toInt(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      trialEndsAt: json['trial_ends_at'] == null
          ? null
          : DateTime.parse(json['trial_ends_at'] as String),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      features: Map<String, bool>.from(json['features'] as Map),
    );

Map<String, dynamic> _$BillingStatusToJson(BillingStatus instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'is_active': instance.isActive,
      'student_limit': instance.studentLimit,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'trial_ends_at': instance.trialEndsAt?.toIso8601String(),
      'days_remaining': instance.daysRemaining,
      'features': instance.features,
    };

BillingProduct _$BillingProductFromJson(Map<String, dynamic> json) =>
    BillingProduct(
      productId: json['product_id'] as String,
      plan: json['plan'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$BillingProductToJson(BillingProduct instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'plan': instance.plan,
      'description': instance.description,
    };
