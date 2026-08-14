import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';
import 'package:lessonaza/features/subscription/domain/repositories/refund_request_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/refund_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_request_sheet.dart';

class _FakeRefundRequestRepository implements RefundRequestRepository {
  int createCalls = 0;
  Exception? throwOnCreate;

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
    createCalls++;
    if (throwOnCreate != null) throw throwOnCreate!;
    return RefundRequest(
      id: 'refund_1',
      subscriptionId: subscriptionId,
      studentId: studentId,
      teacherId: teacherId,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      reason: reason,
      requestedAt: DateTime(2026, 8, 14),
    );
  }

  @override
  Future<List<RefundRequest>> listForStudent(String studentId) async => [];

  @override
  Future<List<RefundRequest>> listForTeacher(String teacherId) async => [];

  @override
  Future<RefundRequest?> latestForSubscription(
    String subscriptionId, {
    required bool asTeacher,
  }) async => null;

  @override
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  }) => throw UnimplementedError();

  @override
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  }) => throw UnimplementedError();
}

Future<void> _openSheet(
  WidgetTester tester,
  _FakeRefundRequestRepository fakeRepo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        refundRequestRepositoryProvider.overrideWith((ref) => fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => RefundRequestSheet.show(
                        context,
                        subscriptionId: 'sub_1',
                        studentId: 'student_1',
                        teacherId: 'teacher_1',
                        studentName: '김민수',
                        estimatedAmount: 300000,
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('RefundRequestSheet — 요청 시트 검증(빈 계좌 차단)', () {
    testWidgets('blocks submit when account number/holder are empty', (
      tester,
    ) async {
      final fakeRepo = _FakeRefundRequestRepository();
      await _openSheet(tester, fakeRepo);

      // Bank name filled, account number + holder left blank.
      await tester.enterText(find.byType(TextFormField).at(0), '국민은행');
      await tester.tap(find.text('요청하기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('계좌번호를 입력해주세요.'), findsOneWidget);
      expect(find.text('예금주를 입력해주세요.'), findsOneWidget);
      expect(fakeRepo.createCalls, 0);
    });

    testWidgets('submits and pops true when all required fields are filled', (
      tester,
    ) async {
      final fakeRepo = _FakeRefundRequestRepository();
      await _openSheet(tester, fakeRepo);

      await tester.enterText(find.byType(TextFormField).at(0), '국민은행');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '110-123-456789',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '홍길동');
      await tester.tap(find.text('요청하기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(fakeRepo.createCalls, 1);
      // Sheet closed after successful submit.
      expect(find.text('환불 요청'), findsNothing);
    });

    testWidgets('shows the reference estimate note', (tester) async {
      final fakeRepo = _FakeRefundRequestRepository();
      await _openSheet(tester, fakeRepo);

      expect(find.textContaining('참고용'), findsOneWidget);
      expect(find.textContaining('300,000원'), findsOneWidget);
    });
  });
}
