import '../../../../core/network/api_client.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/repositories/refund_request_repository.dart';

/// REST client for refund request endpoints (#1271).
///
/// Contract: POST /refund-requests, GET /refund-requests (role-scoped —
/// backend masks the account number for student responses and unmasks it
/// for the teacher only while `requested`), PATCH
/// /refund-requests/{id}/complete, PATCH /refund-requests/{id}/reject.
/// TODO(remote): 백엔드 엔드포인트 확정 후 경로/스키마 정합성 검증 필요.
class RemoteRefundRequestRepository implements RefundRequestRepository {
  final ApiClient _apiClient;

  RemoteRefundRequestRepository(this._apiClient);

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
    final response = await _apiClient.post(
      '/refund-requests',
      data: {
        'subscription_id': subscriptionId,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<RefundRequest>> listForStudent(String studentId) async {
    final response = await _apiClient.get('/refund-requests');
    return _listFromResponse(response.data);
  }

  @override
  Future<List<RefundRequest>> listForTeacher(String teacherId) async {
    final response = await _apiClient.get('/refund-requests');
    return _listFromResponse(response.data);
  }

  @override
  Future<RefundRequest?> latestForSubscription(
    String subscriptionId, {
    required bool asTeacher,
  }) async {
    final response = await _apiClient.get(
      '/refund-requests',
      queryParameters: {'subscription_id': subscriptionId},
    );
    final items = _listFromResponse(response.data);
    if (items.isEmpty) return null;
    return items.reduce((a, b) => a.requestedAt.isAfter(b.requestedAt) ? a : b);
  }

  @override
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  }) async {
    final response = await _apiClient.patch(
      '/refund-requests/$id/complete',
      data: {'processed_amount': processedAmount},
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  }) async {
    final response = await _apiClient.patch(
      '/refund-requests/$id/reject',
      data: {'reject_reason': rejectReason},
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  // ──────────────────────────────────────────────────────────
  // JSON helpers
  // ──────────────────────────────────────────────────────────

  static List<RefundRequest> _listFromResponse(dynamic data) {
    final map = data as Map<String, dynamic>;
    final items =
        (map['refund_requests'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    return items.map(_fromJson).toList(growable: false);
  }

  static RefundRequest _fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolder: json['account_holder'] as String,
      reason: json['reason'] as String?,
      status: _statusFromWire(json['status'] as String),
      processedAmount: json['processed_amount'] as int?,
      rejectReason: json['reject_reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt:
          json['processed_at'] != null
              ? DateTime.parse(json['processed_at'] as String)
              : null,
    );
  }

  static RefundRequestStatus _statusFromWire(String value) {
    switch (value) {
      case 'completed':
        return RefundRequestStatus.completed;
      case 'rejected':
        return RefundRequestStatus.rejected;
      case 'requested':
      default:
        return RefundRequestStatus.requested;
    }
  }
}
