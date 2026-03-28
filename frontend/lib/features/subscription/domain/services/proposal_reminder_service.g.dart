// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_reminder_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$proposalReminderServiceHash() =>
    r'9d7c6021e03523d59e1844869656c315a64d4919';

/// Service for scheduling and managing proposal reminder notifications.
///
/// Implements the auto-reminder feature from subscription_proposal_spec.md:
/// - 24h reminder: Gentle reminder about pending proposal
/// - 48h reminder: Follow-up reminder
/// - 72h reminder: Golden time ending warning (if applicable)
///
/// Copied from [proposalReminderService].
@ProviderFor(proposalReminderService)
final proposalReminderServiceProvider =
    AutoDisposeProvider<ProposalReminderService>.internal(
  proposalReminderService,
  name: r'proposalReminderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proposalReminderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProposalReminderServiceRef
    = AutoDisposeProviderRef<ProposalReminderService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
