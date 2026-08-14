import '../../../../core/utils/account_mask_utils.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/repositories/refund_request_repository.dart';

/// In-memory mock for refund requests (#1271).
///
/// No seed data — a fresh mock session starts with zero requests so the
/// student-entry / empty-state paths are exercised by default.
class MockRefundRequestRepository implements RefundRequestRepository {
  final List<RefundRequest> _requests = [];

  @override
  Future<RefundRequest> create({
    required String subscriptionId,
    required String studentId,
    required String teacherId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? reason,
  }) async {
    final hasActive = _requests.any(
      (r) => r.subscriptionId == subscriptionId && r.isRequested,
    );
    if (hasActive) {
      throw Exception('이미 진행 중인 환불 요청이 있어요.');
    }

    final request = RefundRequest(
      id: 'refund_${DateTime.now().microsecondsSinceEpoch}',
      subscriptionId: subscriptionId,
      studentId: studentId,
      teacherId: teacherId,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      reason: reason,
      requestedAt: DateTime.now(),
    );
    _requests.add(request);
    return request;
  }

  @override
  Future<List<RefundRequest>> listForStudent(String studentId) async {
    return _sorted(
      _requests.where((r) => r.studentId == studentId).map(_maskForStudent),
    );
  }

  @override
  Future<List<RefundRequest>> listForTeacher(String teacherId) async {
    return _sorted(
      _requests.where((r) => r.teacherId == teacherId).map(_maskForTeacher),
    );
  }

  @override
  Future<RefundRequest?> latestForSubscription(
    String subscriptionId, {
    required bool asTeacher,
  }) async {
    final matches = _sorted(
      _requests.where((r) => r.subscriptionId == subscriptionId),
    );
    if (matches.isEmpty) return null;
    final latest = matches.first;
    return asTeacher ? _maskForTeacher(latest) : _maskForStudent(latest);
  }

  @override
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  }) async {
    final index = _requireRequestedIndex(id);
    final updated = _requests[index].copyWith(
      status: RefundRequestStatus.completed,
      processedAmount: processedAmount,
      processedAt: DateTime.now(),
    );
    _requests[index] = updated;
    return updated;
  }

  @override
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  }) async {
    final index = _requireRequestedIndex(id);
    final updated = _requests[index].copyWith(
      status: RefundRequestStatus.rejected,
      rejectReason: rejectReason,
      processedAt: DateTime.now(),
    );
    _requests[index] = updated;
    return updated;
  }

  int _requireRequestedIndex(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Refund request not found: $id');
    }
    if (!_requests[index].isRequested) {
      throw Exception('이미 처리된 환불 요청이에요.');
    }
    return index;
  }

  List<RefundRequest> _sorted(Iterable<RefundRequest> items) {
    return items.toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  RefundRequest _maskForStudent(RefundRequest r) =>
      r.copyWith(accountNumber: maskAccountNumber(r.accountNumber));

  /// Unmasked only while actionable (spec: 선생님은 처리 가능한 동안
  /// 비마스킹).
  RefundRequest _maskForTeacher(RefundRequest r) =>
      r.isActionable
          ? r
          : r.copyWith(accountNumber: maskAccountNumber(r.accountNumber));
}
