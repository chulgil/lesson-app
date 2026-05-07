// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionProposal _$SubscriptionProposalFromJson(
        Map<String, dynamic> json) =>
    SubscriptionProposal(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      studentId: json['student_id'] as String,
      templateId: json['template_id'] as String,
      message: json['message'] as String?,
      status: $enumDecodeNullable(_$ProposalStatusEnumMap, json['status']) ??
          ProposalStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      paymentNotifiedAt: json['payment_notified_at'] == null
          ? null
          : DateTime.parse(json['payment_notified_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      rejectedAt: json['rejected_at'] == null
          ? null
          : DateTime.parse(json['rejected_at'] as String),
      subscriptionId: json['subscription_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      academyId: json['academy_id'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toInt(),
      discountReason: json['discount_reason'] as String?,
      templateIds: (json['template_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendedTemplateId: json['recommended_template_id'] as String?,
      selectedTemplateId: json['selected_template_id'] as String?,
      isAutoProposal: json['is_auto_proposal'] as bool? ?? false,
      paymentStatus: $enumDecodeNullable(
              _$ProposalPaymentStatusEnumMap, json['payment_status']) ??
          ProposalPaymentStatus.pending,
      isAppTransition: json['is_app_transition'] as bool? ?? false,
      lessonRequestId: json['lesson_request_id'] as String?,
      proposalType:
          $enumDecodeNullable(_$ProposalTypeEnumMap, json['proposal_type']) ??
              ProposalType.proposal,
      isRenewal: json['is_renewal'] as bool? ?? false,
      previousSubscriptionId: json['previous_subscription_id'] as String?,
      renewalInitiator: $enumDecodeNullable(
          _$RenewalInitiatorEnumMap, json['renewal_initiator']),
    );

Map<String, dynamic> _$SubscriptionProposalToJson(
        SubscriptionProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacher_id': instance.teacherId,
      'student_id': instance.studentId,
      'template_id': instance.templateId,
      'message': instance.message,
      'status': _$ProposalStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'payment_notified_at': instance.paymentNotifiedAt?.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'rejected_at': instance.rejectedAt?.toIso8601String(),
      'subscription_id': instance.subscriptionId,
      'rejection_reason': instance.rejectionReason,
      'academy_id': instance.academyId,
      'discount_amount': instance.discountAmount,
      'discount_reason': instance.discountReason,
      'template_ids': instance.templateIds,
      'recommended_template_id': instance.recommendedTemplateId,
      'selected_template_id': instance.selectedTemplateId,
      'is_auto_proposal': instance.isAutoProposal,
      'payment_status': _$ProposalPaymentStatusEnumMap[instance.paymentStatus]!,
      'is_app_transition': instance.isAppTransition,
      'lesson_request_id': instance.lessonRequestId,
      'proposal_type': _$ProposalTypeEnumMap[instance.proposalType]!,
      'is_renewal': instance.isRenewal,
      'previous_subscription_id': instance.previousSubscriptionId,
      'renewal_initiator': _$RenewalInitiatorEnumMap[instance.renewalInitiator],
    };

const _$ProposalStatusEnumMap = {
  ProposalStatus.pending: 'pending',
  ProposalStatus.paymentNotified: 'paymentNotified',
  ProposalStatus.confirmed: 'confirmed',
  ProposalStatus.rejected: 'rejected',
  ProposalStatus.expired: 'expired',
  ProposalStatus.cancelled: 'cancelled',
};

const _$ProposalPaymentStatusEnumMap = {
  ProposalPaymentStatus.pending: 'pending',
  ProposalPaymentStatus.completed: 'completed',
};

const _$ProposalTypeEnumMap = {
  ProposalType.proposal: 'proposal',
  ProposalType.directIssue: 'directIssue',
};

const _$RenewalInitiatorEnumMap = {
  RenewalInitiator.system: 'system',
  RenewalInitiator.teacher: 'teacher',
};
