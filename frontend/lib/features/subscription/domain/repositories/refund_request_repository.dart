import '../entities/refund_request.dart';

/// Repository contract for subscription refund requests (#1271).
///
/// Account number masking is a repository-level privacy concern
/// (data-privacy.md Level 1 — access control at repository level): student
/// facing reads are always masked (last 4 digits visible), teacher facing
/// reads are unmasked only while the request is actionable
/// ([RefundRequest.isActionable]).
abstract class RefundRequestRepository {
  /// Student-side: create a new refund request. Server/mock rejects when an
  /// active (`requested`) request already exists for [subscriptionId].
  /// POST /refund-requests
  Future<RefundRequest> create({
    required String subscriptionId,
    required String studentId,
    required String teacherId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? reason,
  });

  /// Student-side: all of the signed-in student's refund requests, account
  /// numbers masked.
  /// GET /refund-requests
  Future<List<RefundRequest>> listForStudent(String studentId);

  /// Teacher-side: refund requests across the teacher's students, account
  /// numbers unmasked only while `requested`.
  /// GET /refund-requests
  Future<List<RefundRequest>> listForTeacher(String teacherId);

  /// Latest refund request (any status) for one subscription, or null when
  /// none exists. Used to render the subscription-detail status badge / box.
  Future<RefundRequest?> latestForSubscription(
    String subscriptionId, {
    required bool asTeacher,
  });

  /// Teacher-side: mark a request completed after the external transfer.
  /// [processedAmount] is the teacher's manually entered final amount —
  /// the estimate shown to both sides is reference-only.
  /// PATCH /refund-requests/{id}/complete
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  });

  /// Teacher-side: reject the request with a required reason.
  /// PATCH /refund-requests/{id}/reject
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  });
}
