import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/l10n/app_strings.dart';

part 'subscription_proposal.g.dart';

/// Who initiated the renewal proposal.
@HiveType(typeId: 100)
enum RenewalInitiator {
  /// System auto-detected low subscription and sent proposal
  @HiveField(0)
  system,

  /// Teacher manually sent renewal proposal
  @HiveField(1)
  teacher,
}

/// Status of a subscription proposal.
@HiveType(typeId: 81)
enum ProposalStatus {
  /// Proposal sent, waiting for student to confirm
  @HiveField(0)
  pending,

  /// Student notified that they have completed payment
  @HiveField(1)
  paymentNotified,

  /// Payment confirmed, subscription issued
  @HiveField(2)
  confirmed,

  /// Student rejected the proposal
  @HiveField(3)
  rejected,

  /// Proposal expired after 7 days
  @HiveField(4)
  expired,

  /// Teacher cancelled the proposal
  @HiveField(5)
  cancelled,
}

/// Payment status for subscription proposals.
/// Used to distinguish between normal flow (pending payment) and app transition (already paid).
@HiveType(typeId: 97)
enum ProposalPaymentStatus {
  /// Payment pending - requires payment confirmation (normal flow)
  @HiveField(0)
  pending,

  /// Payment completed - skip payment confirmation (app transition)
  @HiveField(1)
  completed,
}

/// Extension methods for ProposalPaymentStatus.
extension ProposalPaymentStatusExtension on ProposalPaymentStatus {
  /// Display label in Korean
  String get label {
    switch (this) {
      case ProposalPaymentStatus.pending:
        return AppStrings.proposalPaymentStatusPending;
      case ProposalPaymentStatus.completed:
        return AppStrings.proposalPaymentStatusCompleted;
    }
  }

  /// Description text
  String get description {
    switch (this) {
      case ProposalPaymentStatus.pending:
        return AppStrings.proposalPaymentDescPending;
      case ProposalPaymentStatus.completed:
        return AppStrings.proposalPaymentDescCompleted;
    }
  }

  /// Whether payment confirmation should be skipped
  bool get skipPaymentConfirmation => this == ProposalPaymentStatus.completed;
}

/// Extension methods for ProposalStatus.
extension ProposalStatusExtension on ProposalStatus {
  /// Display label in Korean
  String get label {
    switch (this) {
      case ProposalStatus.pending:
        return AppStrings.proposalStatusPending;
      case ProposalStatus.paymentNotified:
        return AppStrings.proposalStatusPaymentNotified;
      case ProposalStatus.confirmed:
        return AppStrings.proposalStatusConfirmed;
      case ProposalStatus.rejected:
        return AppStrings.proposalStatusRejected;
      case ProposalStatus.expired:
        return AppStrings.expired;
      case ProposalStatus.cancelled:
        return AppStrings.proposalStatusCancelled;
    }
  }

  /// Whether this status is considered active (can still transition)
  bool get isActive {
    return this == ProposalStatus.pending ||
        this == ProposalStatus.paymentNotified;
  }

  /// Whether this status is a terminal state
  bool get isTerminal {
    return this == ProposalStatus.confirmed ||
        this == ProposalStatus.rejected ||
        this == ProposalStatus.expired ||
        this == ProposalStatus.cancelled;
  }
}

/// Type of proposal action.
@HiveType(typeId: 98)
enum ProposalType {
  /// Normal proposal — student receives and decides
  @HiveField(0)
  proposal,

  /// Direct issue — teacher issues subscription immediately
  @HiveField(1)
  directIssue,
}

/// Extension methods for ProposalType.
extension ProposalTypeExtension on ProposalType {
  String get label {
    switch (this) {
      case ProposalType.proposal:
        return AppStrings.proposalTypeProposal;
      case ProposalType.directIssue:
        return AppStrings.proposalTypeDirectIssue;
    }
  }

  bool get isDirectIssue => this == ProposalType.directIssue;
}

/// Subscription proposal - teacher proposes a subscription to a student.
///
/// Flow:
/// 1. Teacher selects student and template
/// 2. Creates proposal (pending)
/// 3. Student receives notification
/// 4. Student makes payment externally and taps "입금 완료" (paymentNotified)
/// 5. Teacher verifies payment and confirms (confirmed → subscription issued)
@HiveType(typeId: 82)
@JsonSerializable()
class SubscriptionProposal extends HiveObject {
  @HiveField(0)
  final String id;

  /// Teacher who created the proposal
  @HiveField(1)
  final String teacherId;

  /// Student receiving the proposal
  @HiveField(2)
  final String studentId;

  /// Template being proposed
  @HiveField(3)
  final String templateId;

  /// Optional message from teacher
  @HiveField(4)
  final String? message;

  /// Current status
  @HiveField(5)
  final ProposalStatus status;

  /// When the proposal was created
  @HiveField(6)
  final DateTime createdAt;

  /// When the proposal expires (7 days after creation)
  @HiveField(7)
  final DateTime expiresAt;

  /// When the student notified payment completion
  @HiveField(8)
  final DateTime? paymentNotifiedAt;

  /// When the teacher confirmed payment
  @HiveField(9)
  final DateTime? confirmedAt;

  /// When the student rejected the proposal
  @HiveField(10)
  final DateTime? rejectedAt;

  /// ID of the subscription created after confirmation
  @HiveField(11)
  final String? subscriptionId;

  /// Reason for rejection (if rejected)
  @HiveField(12)
  final String? rejectionReason;

  /// Academy ID if this proposal is through an academy
  @HiveField(13)
  final String? academyId;

  /// Discount amount applied (e.g., golden time discount)
  @HiveField(14)
  final int? discountAmount;

  /// Discount reason (e.g., "골든타임 할인")
  @HiveField(15)
  final String? discountReason;

  // ============================================================
  // v4 Fields - Multi-select support
  // ============================================================

  /// List of template IDs for multi-choice proposals.
  /// If empty, uses templateId (backward compatibility).
  @HiveField(16)
  final List<String> templateIds;

  /// Recommended template ID (shown with ⭐ for student).
  /// If null, first template is recommended.
  @HiveField(17)
  final String? recommendedTemplateId;

  /// Student's selected template ID (for multi-choice proposals).
  /// Null until student makes a selection.
  @HiveField(18)
  final String? selectedTemplateId;

  /// Whether this is an auto-proposal from trial lesson completion.
  @HiveField(19)
  final bool isAutoProposal;

  /// Payment status - for distinguishing app transition (already paid) from normal flow.
  /// Default: pending (normal flow requiring payment confirmation)
  @HiveField(20)
  final ProposalPaymentStatus paymentStatus;

  /// Whether this proposal is for app transition (existing regular lesson → app).
  /// App transition skips trial and payment confirmation steps.
  @HiveField(21)
  final bool isAppTransition;

  /// Linked lesson request ID (for re-enrollment flow).
  /// Used to restore previous schedule when payment is confirmed.
  @HiveField(22)
  final String? lessonRequestId;

  // ============================================================
  // v7 Fields - Template-First UX
  // ============================================================

  /// Type of proposal: normal proposal (student decides) or direct issue.
  @HiveField(23)
  final ProposalType proposalType;

  // ============================================================
  // v8 Fields - Subscription Renewal
  // ============================================================

  /// Whether this is a renewal proposal (existing subscription re-enrollment).
  @HiveField(24)
  final bool isRenewal;

  /// Previous subscription ID (for renewal proposals).
  @HiveField(25)
  final String? previousSubscriptionId;

  /// Who initiated the renewal (system auto or teacher manual).
  @HiveField(26)
  final RenewalInitiator? renewalInitiator;

  SubscriptionProposal({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.templateId,
    this.message,
    this.status = ProposalStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.paymentNotifiedAt,
    this.confirmedAt,
    this.rejectedAt,
    this.subscriptionId,
    this.rejectionReason,
    this.academyId,
    this.discountAmount,
    this.discountReason,
    this.templateIds = const [],
    this.recommendedTemplateId,
    this.selectedTemplateId,
    this.isAutoProposal = false,
    this.paymentStatus = ProposalPaymentStatus.pending,
    this.isAppTransition = false,
    this.lessonRequestId,
    this.proposalType = ProposalType.proposal,
    this.isRenewal = false,
    this.previousSubscriptionId,
    this.renewalInitiator,
  });

  factory SubscriptionProposal.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionProposalFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionProposalToJson(this);

  /// Whether the proposal has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the proposal can be confirmed (payment notified and not expired)
  bool get canConfirm => status == ProposalStatus.paymentNotified && !isExpired;

  /// Whether the proposal is still active (can transition to another state)
  bool get isActive => status.isActive && !isExpired;

  /// Whether the proposal is pending and student can respond
  bool get canRespond => status == ProposalStatus.pending && !isExpired;

  /// Time remaining until expiration
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  /// Whether this proposal is through an academy
  bool get isAcademyProposal => academyId != null;

  /// Whether discount is applied
  bool get hasDiscount => discountAmount != null && discountAmount! > 0;

  /// Status display label
  String get statusLabel => status.label;

  // ============================================================
  // v4 Helper Methods - Multi-select
  // ============================================================

  /// Whether this is a multi-choice proposal.
  bool get isMultiChoice => templateIds.isNotEmpty;

  /// All template IDs (for multi-choice, returns templateIds; otherwise returns [templateId]).
  List<String> get allTemplateIds =>
      templateIds.isNotEmpty ? templateIds : [templateId];

  /// The effective template ID for subscription creation.
  /// For multi-choice: uses selectedTemplateId (must be set by student).
  /// For single: uses templateId.
  String get effectiveTemplateId =>
      selectedTemplateId ??
      (templateIds.isNotEmpty ? templateIds.first : templateId);

  /// The recommended template ID (for display with ⭐).
  /// Returns recommendedTemplateId if set, otherwise first template.
  String get effectiveRecommendedTemplateId =>
      recommendedTemplateId ?? allTemplateIds.first;

  /// Whether student needs to select a template (multi-choice and not yet selected).
  bool get needsTemplateSelection =>
      isMultiChoice && selectedTemplateId == null;

  /// Whether the given template ID is the recommended one.
  bool isRecommended(String id) => id == effectiveRecommendedTemplateId;

  /// Formatted time since creation
  String get timeSinceCreated {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) {
      return AppStrings.timeAgoDays(diff.inDays);
    } else if (diff.inHours > 0) {
      return AppStrings.timeAgoHours(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return AppStrings.timeAgoMinutes(diff.inMinutes);
    }
    return AppStrings.timeAgoJustNow;
  }

  /// Formatted expiration time
  String get formattedExpiration {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return AppStrings.expired;
    } else if (diff.inDays > 0) {
      return AppStrings.expiresInDays(diff.inDays);
    } else if (diff.inHours > 0) {
      return AppStrings.expiresInHours(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return AppStrings.expiresInMinutes(diff.inMinutes);
    }
    return AppStrings.expiresVerySoon;
  }

  /// Whether payment confirmation should be skipped (app transition case)
  bool get skipPaymentConfirmation => paymentStatus.skipPaymentConfirmation;

  /// Whether this proposal can be immediately confirmed (app transition with completed payment)
  bool get canImmediateConfirm =>
      isAppTransition && paymentStatus == ProposalPaymentStatus.completed;

  /// Whether this is a direct issue (no student confirmation needed)
  bool get isDirectIssue => proposalType == ProposalType.directIssue;

  SubscriptionProposal copyWith({
    String? id,
    String? teacherId,
    String? studentId,
    String? templateId,
    String? message,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? paymentNotifiedAt,
    DateTime? confirmedAt,
    DateTime? rejectedAt,
    String? subscriptionId,
    String? rejectionReason,
    String? academyId,
    int? discountAmount,
    String? discountReason,
    List<String>? templateIds,
    String? recommendedTemplateId,
    String? selectedTemplateId,
    bool? isAutoProposal,
    ProposalPaymentStatus? paymentStatus,
    bool? isAppTransition,
    String? lessonRequestId,
    ProposalType? proposalType,
    bool? isRenewal,
    String? previousSubscriptionId,
    RenewalInitiator? renewalInitiator,
  }) {
    return SubscriptionProposal(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      templateId: templateId ?? this.templateId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      paymentNotifiedAt: paymentNotifiedAt ?? this.paymentNotifiedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      academyId: academyId ?? this.academyId,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      templateIds: templateIds ?? this.templateIds,
      recommendedTemplateId:
          recommendedTemplateId ?? this.recommendedTemplateId,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      isAutoProposal: isAutoProposal ?? this.isAutoProposal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isAppTransition: isAppTransition ?? this.isAppTransition,
      lessonRequestId: lessonRequestId ?? this.lessonRequestId,
      proposalType: proposalType ?? this.proposalType,
      isRenewal: isRenewal ?? this.isRenewal,
      previousSubscriptionId:
          previousSubscriptionId ?? this.previousSubscriptionId,
      renewalInitiator: renewalInitiator ?? this.renewalInitiator,
    );
  }

  @override
  String toString() =>
      'SubscriptionProposal(id: $id, status: $status, teacherId: $teacherId, studentId: $studentId)';
}
