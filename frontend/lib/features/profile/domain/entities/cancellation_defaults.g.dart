// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_defaults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancellationDefaults _$CancellationDefaultsFromJson(
        Map<String, dynamic> json) =>
    CancellationDefaults(
      id: json['id'] as String,
      cancellationDeadlineHours:
          (json['cancellation_deadline_hours'] as num?)?.toInt() ?? 12,
      studentCompensationExtraMinutesEnabled:
          json['student_compensation_extra_minutes_enabled'] as bool? ?? true,
      includeExtraMinutesTextOnLateCancel:
          json['include_extra_minutes_text_on_late_cancel'] as bool? ?? true,
      studentCompensationExtraMinutesMessage:
          json['student_compensation_extra_minutes_message'] as String?,
      notifyOwnerOnLateCancel:
          json['notify_owner_on_late_cancel'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CancellationDefaultsToJson(
        CancellationDefaults instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cancellation_deadline_hours': instance.cancellationDeadlineHours,
      'student_compensation_extra_minutes_enabled':
          instance.studentCompensationExtraMinutesEnabled,
      'include_extra_minutes_text_on_late_cancel':
          instance.includeExtraMinutesTextOnLateCancel,
      'student_compensation_extra_minutes_message':
          instance.studentCompensationExtraMinutesMessage,
      'notify_owner_on_late_cancel': instance.notifyOwnerOnLateCancel,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
