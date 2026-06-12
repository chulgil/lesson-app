import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Local draft of a subscription proposal — persisted when the teacher taps
/// "나중에" in the E3 phone-verification gate modal (#695).
///
/// Spec: docs/specs/user/phone_verification_policy.md §4.4 / §4.5.
///
/// Domain rule: no Hive annotations on domain entities — this storage lives
/// in the data layer and serializes the draft as a raw JSON string.
///
/// Key format: `teacher:<userId>:proposal_draft:<studentId>`
/// Expiry: 7 days (matches the proposal expiry window).
class ProposalDraftStorage {
  ProposalDraftStorage();

  static const _boxName = 'proposal_drafts';
  static const draftTtlDays = 7;

  Box? _box;

  Future<Box> _openBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  String _key(String userId, String studentId) =>
      'teacher:$userId:proposal_draft:$studentId';

  /// Save a draft. Overwrites any existing draft for the same (user, student).
  Future<void> save({
    required String userId,
    required String studentId,
    required String? templateId,
    required int amount,
    required int totalLessons,
    required int validityDays,
    required String? membershipId,
  }) async {
    final box = await _openBox();
    final payload = jsonEncode({
      'templateId': templateId,
      'amount': amount,
      'totalLessons': totalLessons,
      'validityDays': validityDays,
      'membershipId': membershipId,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await box.put(_key(userId, studentId), payload);
  }

  /// Load the draft for (user, student).
  ///
  /// - No draft → `(draft: null, expiredDiscarded: false)`
  /// - Expired (7+ days) → discards it and returns
  ///   `(draft: null, expiredDiscarded: true)` so callers can instrument
  ///   the `subscription.draft_expired` event.
  /// - Valid → `(draft: <draft>, expiredDiscarded: false)`
  Future<ProposalDraftLoadResult> load(String userId, String studentId) async {
    final box = await _openBox();
    final raw = box.get(_key(userId, studentId)) as String?;
    if (raw == null) return const ProposalDraftLoadResult(draft: null);

    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final savedAt = DateTime.tryParse(map['savedAt'] as String? ?? '');
    if (savedAt == null) {
      await box.delete(_key(userId, studentId));
      return const ProposalDraftLoadResult(draft: null);
    }

    final age = DateTime.now().difference(savedAt);
    if (age.inDays >= draftTtlDays) {
      await box.delete(_key(userId, studentId));
      return const ProposalDraftLoadResult(draft: null, expiredDiscarded: true);
    }

    return ProposalDraftLoadResult(
      draft: ProposalDraft(
        templateId: map['templateId'] as String?,
        amount: (map['amount'] as int?) ?? 0,
        totalLessons: (map['totalLessons'] as int?) ?? 0,
        validityDays: (map['validityDays'] as int?) ?? 0,
        membershipId: map['membershipId'] as String?,
        savedAt: savedAt,
        ageDays: age.inDays,
      ),
    );
  }

  /// Permanently delete the draft for this (user, student).
  Future<void> delete(String userId, String studentId) async {
    final box = await _openBox();
    await box.delete(_key(userId, studentId));
  }
}

/// Result of [ProposalDraftStorage.load].
class ProposalDraftLoadResult {
  const ProposalDraftLoadResult({
    required this.draft,
    this.expiredDiscarded = false,
  });

  final ProposalDraft? draft;

  /// True when an expired draft was found and auto-discarded by this load.
  final bool expiredDiscarded;
}

/// Immutable draft value object returned by [ProposalDraftStorage.load].
class ProposalDraft {
  const ProposalDraft({
    required this.templateId,
    required this.amount,
    required this.totalLessons,
    required this.validityDays,
    required this.membershipId,
    required this.savedAt,
    required this.ageDays,
  });

  final String? templateId;
  final int amount;
  final int totalLessons;
  final int validityDays;
  final String? membershipId;
  final DateTime savedAt;
  final int ageDays;
}
