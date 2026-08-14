import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';

RefundRequest _request({
  RefundRequestStatus status = RefundRequestStatus.requested,
  int? processedAmount,
  String? rejectReason,
}) {
  return RefundRequest(
    id: 'refund_1',
    subscriptionId: 'sub_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    bankName: '신한은행',
    accountNumber: '110-123-456789',
    accountHolder: '홍길동',
    status: status,
    processedAmount: processedAmount,
    rejectReason: rejectReason,
    requestedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('RefundRequest status getters', () {
    test('requested', () {
      final r = _request();
      expect(r.isRequested, isTrue);
      expect(r.isCompleted, isFalse);
      expect(r.isRejected, isFalse);
      expect(r.isActionable, isTrue);
    });

    test('completed', () {
      final r = _request(
        status: RefundRequestStatus.completed,
        processedAmount: 100000,
      );
      expect(r.isCompleted, isTrue);
      expect(r.isRequested, isFalse);
      expect(r.isActionable, isFalse);
      expect(r.processedAmount, 100000);
    });

    test('rejected', () {
      final r = _request(
        status: RefundRequestStatus.rejected,
        rejectReason: '재발급 조건 미충족',
      );
      expect(r.isRejected, isTrue);
      expect(r.isRequested, isFalse);
      expect(r.isActionable, isFalse);
      expect(r.rejectReason, '재발급 조건 미충족');
    });
  });

  test('copyWith replaces only the given fields', () {
    final original = _request();
    final updated = original.copyWith(
      status: RefundRequestStatus.completed,
      processedAmount: 50000,
    );

    expect(updated.id, original.id);
    expect(updated.status, RefundRequestStatus.completed);
    expect(updated.processedAmount, 50000);
    expect(updated.accountNumber, original.accountNumber);
  });
}
