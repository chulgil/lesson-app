import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/payment_inquiry_storage.dart';

part 'payment_inquiry_provider.g.dart';

/// Storage instance provider — overridden in tests with an in-memory fake so
/// the records notifier can be exercised without Hive.
@Riverpod(keepAlive: true)
PaymentInquiryStorage paymentInquiryStorage(PaymentInquiryStorageRef ref) =>
    PaymentInquiryStorage();

/// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
///
/// Mutations update the Hive store and the in-memory state directly (no
/// invalidateSelf) so the cached box / family instance survives.
///
/// The hold memo is a best-effort re-matching aid, never blocking issuance —
/// storage I/O failures (e.g. Hive unavailable) are swallowed so they never
/// surface as errors in the payment flow.
@riverpod
class PaymentInquiryRecords extends _$PaymentInquiryRecords {
  late String _teacherId;

  @override
  Future<Map<String, DateTime>> build(String teacherId) async {
    _teacherId = teacherId;
    final storage = ref.read(paymentInquiryStorageProvider);
    try {
      return await storage.loadAll(teacherId);
    } catch (e) {
      debugPrint('[PaymentInquiryRecords] loadAll failed: $e');
      return const {};
    }
  }

  /// Mark a proposal as "확인 보류" (records the current inquiry time).
  Future<void> recordInquiry(String proposalId) async {
    final storage = ref.read(paymentInquiryStorageProvider);
    try {
      await storage.recordInquiry(_teacherId, proposalId);
    } catch (e) {
      debugPrint('[PaymentInquiryRecords] recordInquiry failed: $e');
    }
    final next = Map<String, DateTime>.from(state.valueOrNull ?? const {});
    next[proposalId] = DateTime.now();
    state = AsyncValue.data(next);
  }

  /// Clear the "확인 보류" record (e.g. once the subscription is issued).
  Future<void> clear(String proposalId) async {
    final storage = ref.read(paymentInquiryStorageProvider);
    try {
      await storage.clear(_teacherId, proposalId);
    } catch (e) {
      debugPrint('[PaymentInquiryRecords] clear failed: $e');
    }
    final next = Map<String, DateTime>.from(state.valueOrNull ?? const {});
    next.remove(proposalId);
    state = AsyncValue.data(next);
  }
}
