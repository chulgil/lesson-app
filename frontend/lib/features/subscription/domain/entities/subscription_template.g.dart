// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionTemplate _$SubscriptionTemplateFromJson(
        Map<String, dynamic> json) =>
    SubscriptionTemplate(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      ownerType: $enumDecode(
          _$SubscriptionTemplateOwnerTypeEnumMap, json['owner_type']),
      name: json['name'] as String,
      totalLessons: (json['total_lessons'] as num).toInt(),
      lessonDurationMinutes: (json['lesson_duration_minutes'] as num).toInt(),
      validityDays: (json['validity_days'] as num).toInt(),
      price: (json['price'] as num).toInt(),
      regularPrice: (json['regular_price'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      rescheduleAllowance: (json['reschedule_allowance'] as num?)?.toInt() ?? 2,
      isAutoProposalEnabled: json['is_auto_proposal_enabled'] as bool? ?? true,
      appliesTo: $enumDecodeNullable(
          _$SubscriptionAppliesToEnumMap, json['applies_to']),
      groupClassId: json['group_class_id'] as String?,
    );

Map<String, dynamic> _$SubscriptionTemplateToJson(
        SubscriptionTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'owner_type': _$SubscriptionTemplateOwnerTypeEnumMap[instance.ownerType]!,
      'name': instance.name,
      'total_lessons': instance.totalLessons,
      'lesson_duration_minutes': instance.lessonDurationMinutes,
      'validity_days': instance.validityDays,
      'price': instance.price,
      'regular_price': instance.regularPrice,
      'is_active': instance.isActive,
      'display_order': instance.displayOrder,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'reschedule_allowance': instance.rescheduleAllowance,
      'is_auto_proposal_enabled': instance.isAutoProposalEnabled,
      'applies_to': _$SubscriptionAppliesToEnumMap[instance.appliesTo],
      'group_class_id': instance.groupClassId,
    };

const _$SubscriptionTemplateOwnerTypeEnumMap = {
  SubscriptionTemplateOwnerType.teacher: 'teacher',
  SubscriptionTemplateOwnerType.academy: 'academy',
};

const _$SubscriptionAppliesToEnumMap = {
  SubscriptionAppliesTo.oneToOne: 'oneToOne',
  SubscriptionAppliesTo.group: 'group',
  SubscriptionAppliesTo.universal: 'universal',
};
