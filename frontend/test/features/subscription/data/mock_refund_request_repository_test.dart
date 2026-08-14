import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_refund_request_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';

void main() {
  late MockRefundRequestRepository repo;

  setUp(() {
    repo = MockRefundRequestRepository();
  });

  Future<RefundRequest> createSample() {
    return repo.create(
      subscriptionId: 'sub_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      bankName: '신한은행',
      accountNumber: '110-123-456789',
      accountHolder: '홍길동',
      reason: '더 이상 다니지 않아요',
    );
  }

  group('create', () {
    test('creates a requested refund request', () async {
      final created = await createSample();
      expect(created.status, RefundRequestStatus.requested);
      expect(created.subscriptionId, 'sub_1');
    });

    test('blocks a second active request for the same subscription', () async {
      await createSample();
      expect(() => createSample(), throwsException);
    });

    test('allows a new request once the prior one is resolved', () async {
      final first = await createSample();
      await repo.complete(id: first.id, processedAmount: 100000);
      // No exception — the prior request is no longer active.
      final second = await createSample();
      expect(second.status, RefundRequestStatus.requested);
    });
  });

  group('masking', () {
    test('listForStudent always masks the account number', () async {
      await createSample();
      final list = await repo.listForStudent('student_1');
      expect(list.single.accountNumber, '***-***-**6789');
    });

    test('listForTeacher unmasks while requested', () async {
      await createSample();
      final list = await repo.listForTeacher('teacher_1');
      expect(list.single.accountNumber, '110-123-456789');
    });

    test('listForTeacher masks once resolved (no longer actionable)', () async {
      final created = await createSample();
      await repo.complete(id: created.id, processedAmount: 100000);
      final list = await repo.listForTeacher('teacher_1');
      expect(list.single.accountNumber, '***-***-**6789');
    });
  });

  group('latestForSubscription', () {
    test('returns null when no request exists', () async {
      final latest = await repo.latestForSubscription(
        'sub_none',
        asTeacher: true,
      );
      expect(latest, isNull);
    });

    test('returns the most recent request, masked per viewer role', () async {
      await createSample();
      final asStudent = await repo.latestForSubscription(
        'sub_1',
        asTeacher: false,
      );
      final asTeacher = await repo.latestForSubscription(
        'sub_1',
        asTeacher: true,
      );
      expect(asStudent!.accountNumber, '***-***-**6789');
      expect(asTeacher!.accountNumber, '110-123-456789');
    });
  });

  group('complete', () {
    test('sets status/processedAmount/processedAt', () async {
      final created = await createSample();
      final completed = await repo.complete(
        id: created.id,
        processedAmount: 250000,
      );
      expect(completed.status, RefundRequestStatus.completed);
      expect(completed.processedAmount, 250000);
      expect(completed.processedAt, isNotNull);
    });

    test('rejects completing an already-resolved request', () async {
      final created = await createSample();
      await repo.complete(id: created.id, processedAmount: 100000);
      expect(
        () => repo.complete(id: created.id, processedAmount: 100000),
        throwsException,
      );
    });
  });

  group('reject', () {
    test('sets status/rejectReason/processedAt', () async {
      final created = await createSample();
      final rejected = await repo.reject(
        id: created.id,
        rejectReason: '정책상 환불 불가',
      );
      expect(rejected.status, RefundRequestStatus.rejected);
      expect(rejected.rejectReason, '정책상 환불 불가');
      expect(rejected.processedAt, isNotNull);
    });
  });
}
