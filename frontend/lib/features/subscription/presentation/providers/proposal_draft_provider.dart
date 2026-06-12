import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../analytics/domain/services/analytics_event_logger.dart';
import '../../../analytics/presentation/providers/analytics_event_logger_provider.dart';
import '../../data/repositories/proposal_draft_storage.dart';

part 'proposal_draft_provider.g.dart';

/// Application-layer storage provider for subscription proposal drafts (#695).
///
/// Spec: docs/specs/user/phone_verification_policy.md §4.4 — "나중에" saves
/// the in-progress form to local Hive storage. The storage instance is kept
/// alive; individual load/save/delete operations are called imperatively
/// from the screen and the actions mixin.
@Riverpod(keepAlive: true)
ProposalDraftStorage proposalDraftStorage(ProposalDraftStorageRef ref) =>
    ProposalDraftStorage();

/// Loads the current draft for (userId, studentId).
/// Returns `null` if no valid (non-expired) draft exists.
///
/// Side-effect: when an expired draft is auto-discarded by this load, the
/// `subscription.draft_expired` metric event is recorded (spec §5.5).
@riverpod
Future<ProposalDraft?> proposalDraft(
  ProposalDraftRef ref,
  String userId,
  String studentId,
) async {
  final storage = ref.watch(proposalDraftStorageProvider);
  try {
    final result = await storage.load(userId, studentId);
    if (result.expiredDiscarded) {
      ref.read(analyticsEventLoggerProvider).log(AnalyticsEvents.draftExpired, {
        'userId': userId,
        'subscriptionDraftId': studentId,
      });
    }
    return result.draft;
  } catch (_) {
    // Storage unavailable (e.g. Hive not initialized in widget tests) —
    // treat as "no draft" so the host screen renders without a banner.
    return null;
  }
}
