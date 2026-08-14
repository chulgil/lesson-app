import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../notifications/notifications_facade.dart'
    show refundNotificationServiceProvider;
import '../../data/repositories/mock_refund_request_repository.dart';
import '../../data/repositories/remote_refund_request_repository.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/repositories/refund_request_repository.dart';

part 'refund_request_providers.g.dart';

/// Repository provider — switches between Mock and Remote (#1271).
@Riverpod(keepAlive: true)
RefundRequestRepository refundRequestRepository(Ref ref) =>
    createRepository<RefundRequestRepository>(
      ref: ref,
      mock: () => MockRefundRequestRepository(),
      remote: (api) => RemoteRefundRequestRepository(api),
    );

/// Student-side: all of the signed-in student's refund requests (masked).
@riverpod
Future<List<RefundRequest>> studentRefundRequests(
  Ref ref,
  String studentId,
) async {
  final repo = ref.watch(refundRequestRepositoryProvider);
  return repo.listForStudent(studentId);
}

/// Teacher-side: all refund requests across the teacher's students.
@riverpod
Future<List<RefundRequest>> teacherRefundRequests(
  Ref ref,
  String teacherId,
) async {
  final repo = ref.watch(refundRequestRepositoryProvider);
  return repo.listForTeacher(teacherId);
}

/// Teacher-side: the still-actionable subset, for the pending dashboard
/// card and list screen.
@riverpod
Future<List<RefundRequest>> teacherPendingRefundRequests(
  Ref ref,
  String teacherId,
) async {
  final all = await ref.watch(teacherRefundRequestsProvider(teacherId).future);
  return all.where((r) => r.isRequested).toList();
}

/// Teacher-side: pending count for the dashboard badge.
@riverpod
Future<int> teacherPendingRefundRequestCount(Ref ref, String teacherId) async {
  final pending = await ref.watch(
    teacherPendingRefundRequestsProvider(teacherId).future,
  );
  return pending.length;
}

/// Latest refund request (any status) for one subscription, viewer-scoped.
/// Drives the subscription-detail entry point / status badge / action box.
@riverpod
Future<RefundRequest?> refundRequestForSubscription(
  Ref ref, {
  required String subscriptionId,
  required bool asTeacher,
}) async {
  final repo = ref.watch(refundRequestRepositoryProvider);
  return repo.latestForSubscription(subscriptionId, asTeacher: asTeacher);
}

/// Mutation actions — create (student) / complete / reject (teacher), with
/// cache invalidation and best-effort notification dispatch.
@riverpod
RefundRequestActions refundRequestActions(Ref ref) => RefundRequestActions(ref);

class RefundRequestActions {
  RefundRequestActions(this._ref);

  final Ref _ref;

  /// Student-side: submit a refund request. [studentName] is supplied by the
  /// caller (already loaded for the current screen) to notify the teacher.
  Future<RefundRequest> create({
    required String subscriptionId,
    required String studentId,
    required String teacherId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required String studentName,
    String? reason,
  }) async {
    final repo = _ref.read(refundRequestRepositoryProvider);
    final request = await repo.create(
      subscriptionId: subscriptionId,
      studentId: studentId,
      teacherId: teacherId,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      reason: reason,
    );
    _invalidate(
      subscriptionId: subscriptionId,
      studentId: studentId,
      teacherId: teacherId,
    );
    await _ref
        .read(refundNotificationServiceProvider)
        .sendRequested(teacherId: teacherId, studentName: studentName);
    return request;
  }

  /// Teacher-side: mark the request completed with the manually entered
  /// final transfer amount.
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  }) async {
    final repo = _ref.read(refundRequestRepositoryProvider);
    final updated = await repo.complete(
      id: id,
      processedAmount: processedAmount,
    );
    _invalidate(
      subscriptionId: updated.subscriptionId,
      studentId: updated.studentId,
      teacherId: updated.teacherId,
    );
    await _ref
        .read(refundNotificationServiceProvider)
        .sendCompleted(
          studentId: updated.studentId,
          processedAmount: processedAmount,
        );
    return updated;
  }

  /// Teacher-side: reject the request with a required reason.
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  }) async {
    final repo = _ref.read(refundRequestRepositoryProvider);
    final updated = await repo.reject(id: id, rejectReason: rejectReason);
    _invalidate(
      subscriptionId: updated.subscriptionId,
      studentId: updated.studentId,
      teacherId: updated.teacherId,
    );
    await _ref
        .read(refundNotificationServiceProvider)
        .sendRejected(studentId: updated.studentId, rejectReason: rejectReason);
    return updated;
  }

  void _invalidate({
    required String subscriptionId,
    required String studentId,
    required String teacherId,
  }) {
    _ref.invalidate(studentRefundRequestsProvider(studentId));
    _ref.invalidate(teacherRefundRequestsProvider(teacherId));
    _ref.invalidate(
      refundRequestForSubscriptionProvider(
        subscriptionId: subscriptionId,
        asTeacher: true,
      ),
    );
    _ref.invalidate(
      refundRequestForSubscriptionProvider(
        subscriptionId: subscriptionId,
        asTeacher: false,
      ),
    );
  }
}
