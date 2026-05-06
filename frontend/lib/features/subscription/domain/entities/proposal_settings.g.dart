// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalSettings _$ProposalSettingsFromJson(Map<String, dynamic> json) =>
    ProposalSettings(
      teacherId: json['teacher_id'] as String,
      autoProposalEnabled: json['auto_proposal_enabled'] as bool? ?? true,
      autoProposalTemplateIds:
          (json['auto_proposal_template_ids'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      recommendedTemplateId: json['recommended_template_id'] as String?,
      goldenTimeDiscountPercent:
          (json['golden_time_discount_percent'] as num?)?.toInt() ?? 10,
      goldenTimeHours: (json['golden_time_hours'] as num?)?.toInt() ?? 24,
      autoReminderEnabled: json['auto_reminder_enabled'] as bool? ?? true,
      reminderHours: (json['reminder_hours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [24, 48, 72],
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      autoRenewalEnabled: json['auto_renewal_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$ProposalSettingsToJson(ProposalSettings instance) =>
    <String, dynamic>{
      'teacher_id': instance.teacherId,
      'auto_proposal_enabled': instance.autoProposalEnabled,
      'auto_proposal_template_ids': instance.autoProposalTemplateIds,
      'recommended_template_id': instance.recommendedTemplateId,
      'golden_time_discount_percent': instance.goldenTimeDiscountPercent,
      'golden_time_hours': instance.goldenTimeHours,
      'auto_reminder_enabled': instance.autoReminderEnabled,
      'reminder_hours': instance.reminderHours,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'auto_renewal_enabled': instance.autoRenewalEnabled,
    };
