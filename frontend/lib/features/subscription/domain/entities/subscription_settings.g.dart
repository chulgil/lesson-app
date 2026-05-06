// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageDiscountPolicy _$PackageDiscountPolicyFromJson(
  Map<String, dynamic> json,
) => PackageDiscountPolicy(
  minLessons: (json['min_lessons'] as num).toInt(),
  type: $enumDecode(_$DiscountTypeEnumMap, json['type']),
  value: (json['value'] as num).toInt(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$PackageDiscountPolicyToJson(
  PackageDiscountPolicy instance,
) => <String, dynamic>{
  'min_lessons': instance.minLessons,
  'type': _$DiscountTypeEnumMap[instance.type]!,
  'value': instance.value,
  'description': instance.description,
};

const _$DiscountTypeEnumMap = {
  DiscountType.discount: 'discount',
  DiscountType.bonusLessons: 'bonusLessons',
};

SubscriptionSettings _$SubscriptionSettingsFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettings(
  id: json['id'] as String,
  teacherId: json['teacher_id'] as String?,
  organizationId: json['organization_id'] as String?,
  renewalAlertThreshold:
      (json['renewal_alert_threshold'] as num?)?.toInt() ?? 1,
  renewalAlertDays: (json['renewal_alert_days'] as num?)?.toInt() ?? 7,
  discountPolicies:
      (json['discount_policies'] as List<dynamic>?)
          ?.map(
            (e) => PackageDiscountPolicy.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  enablePushNotification: json['enable_push_notification'] as bool? ?? true,
  enableBadge: json['enable_badge'] as bool? ?? true,
  notifyParent: json['notify_parent'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SubscriptionSettingsToJson(
  SubscriptionSettings instance,
) => <String, dynamic>{
  'id': instance.id,
  'teacher_id': instance.teacherId,
  'organization_id': instance.organizationId,
  'renewal_alert_threshold': instance.renewalAlertThreshold,
  'renewal_alert_days': instance.renewalAlertDays,
  'discount_policies':
      instance.discountPolicies.map((e) => e.toJson()).toList(),
  'enable_push_notification': instance.enablePushNotification,
  'enable_badge': instance.enableBadge,
  'notify_parent': instance.notifyParent,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
