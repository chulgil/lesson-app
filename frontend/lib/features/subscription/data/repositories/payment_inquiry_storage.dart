import 'package:hive_flutter/hive_flutter.dart';

/// Local record of "입금 미확인 → 확인 보류" inquiries (#772).
///
/// When a teacher taps "입금 미확인" on the payment-confirm screen, we stamp the
/// inquiry time so the card can show a "확인 보류" badge + "마지막 문의 N분 전" and
/// the list can filter to held items. This is the teacher's private re-matching
/// memo (the student / BE don't need it), so it lives device-locally — mirroring
/// [ProposalDraftStorage] rather than touching the proposal entity or BE.
///
/// Key format: `teacher:<userId>:payment_inquiry:<proposalId>`
/// Value: inquiry timestamp (ISO8601).
/// Expiry: 7 days (matches the proposal expiry window).
///
/// Methods are instance methods (not static) so tests can subclass with an
/// in-memory map and avoid Hive initialisation.
class PaymentInquiryStorage {
  PaymentInquiryStorage();

  static const _boxName = 'payment_inquiries';
  static const inquiryTtlDays = 7;

  Box? _box;

  Future<Box> _openBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  String _prefix(String userId) => 'teacher:$userId:payment_inquiry:';
  String _key(String userId, String proposalId) =>
      '${_prefix(userId)}$proposalId';

  /// Stamp (or refresh) the inquiry time for a proposal.
  Future<void> recordInquiry(String userId, String proposalId) async {
    final box = await _openBox();
    await box.put(_key(userId, proposalId), DateTime.now().toIso8601String());
  }

  /// Load all inquiry records for a teacher (proposalId → last inquiry time).
  /// Records older than [inquiryTtlDays] (or unparseable) are pruned on read.
  Future<Map<String, DateTime>> loadAll(String userId) async {
    final box = await _openBox();
    final prefix = _prefix(userId);
    final result = <String, DateTime>{};
    final staleKeys = <String>[];

    for (final key in box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = box.get(key) as String?;
      final at = raw == null ? null : DateTime.tryParse(raw);
      if (at == null) {
        staleKeys.add(key);
        continue;
      }
      if (DateTime.now().difference(at).inDays >= inquiryTtlDays) {
        staleKeys.add(key);
        continue;
      }
      result[key.substring(prefix.length)] = at;
    }

    for (final key in staleKeys) {
      await box.delete(key);
    }
    return result;
  }

  /// Remove a record (e.g. when the proposal is confirmed/issued).
  Future<void> clear(String userId, String proposalId) async {
    final box = await _openBox();
    await box.delete(_key(userId, proposalId));
  }
}
