// 선생님 완료/반려 흐름(확인 다이얼로그 포함) — #1271.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';
import 'package:lessonaza/features/subscription/domain/repositories/refund_request_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/refund_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_action_box.dart';

class _FakeRefundRequestRepository implements RefundRequestRepository {
  int completeCalls = 0;
  int rejectCalls = 0;
  int? lastProcessedAmount;
  String? lastRejectReason;

  final RefundRequest seed;
  _FakeRefundRequestRepository(this.seed);

  @override
  Future<RefundRequest> create({
    required String subscriptionId,
    required String studentId,
    required String teacherId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<List<RefundRequest>> listForStudent(String studentId) async => [];

  @override
  Future<List<RefundRequest>> listForTeacher(String teacherId) async => [];

  @override
  Future<RefundRequest?> latestForSubscription(
    String subscriptionId, {
    required bool asTeacher,
  }) async => seed;

  @override
  Future<RefundRequest> complete({
    required String id,
    required int processedAmount,
  }) async {
    completeCalls++;
    lastProcessedAmount = processedAmount;
    return seed.copyWith(
      status: RefundRequestStatus.completed,
      processedAmount: processedAmount,
    );
  }

  @override
  Future<RefundRequest> reject({
    required String id,
    required String rejectReason,
  }) async {
    rejectCalls++;
    lastRejectReason = rejectReason;
    return seed.copyWith(
      status: RefundRequestStatus.rejected,
      rejectReason: rejectReason,
    );
  }
}

RefundRequest _seedRequest() {
  return RefundRequest(
    id: 'refund_1',
    subscriptionId: 'sub_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    bankName: '신한은행',
    accountNumber: '110-123-456789',
    accountHolder: '홍길동',
    status: RefundRequestStatus.requested,
    requestedAt: DateTime(2026, 8, 14),
  );
}

Widget _scoped(_FakeRefundRequestRepository fakeRepo, Widget child) {
  return ProviderScope(
    overrides: [
      refundRequestRepositoryProvider.overrideWith((ref) => fakeRepo),
    ],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('RefundActionBox — complete flow', () {
    testWidgets('blocks complete when amount is empty', (tester) async {
      final fakeRepo = _FakeRefundRequestRepository(_seedRequest());
      await tester.pumpWidget(
        _scoped(fakeRepo, RefundActionBox(request: _seedRequest())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.refundActionBoxComplete));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(AppStrings.refundActionBoxAmountValidation),
        findsOneWidget,
      );
      expect(fakeRepo.completeCalls, 0);
    });

    testWidgets('shows a confirm dialog before completing, then calls repo', (
      tester,
    ) async {
      final fakeRepo = _FakeRefundRequestRepository(_seedRequest());
      await tester.pumpWidget(
        _scoped(
          fakeRepo,
          RefundActionBox(request: _seedRequest(), estimatedAmount: 300000),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.refundActionBoxComplete));
      await tester.pumpAndSettle();

      // Confirm dialog appears — repo not yet called.
      expect(
        find.text(AppStrings.refundActionBoxCompleteConfirmTitle),
        findsOneWidget,
      );
      expect(fakeRepo.completeCalls, 0);

      await tester.tap(find.text(AppStrings.refundActionBoxComplete).last);
      await tester.pumpAndSettle();

      expect(fakeRepo.completeCalls, 1);
      expect(fakeRepo.lastProcessedAmount, 300000);
      expect(
        find.text(AppStrings.refundActionBoxCompleteSuccess),
        findsOneWidget,
      );
    });
  });

  group('RefundActionBox — reject flow', () {
    testWidgets('reject dialog requires a reason before confirming', (
      tester,
    ) async {
      final fakeRepo = _FakeRefundRequestRepository(_seedRequest());
      await tester.pumpWidget(
        _scoped(fakeRepo, RefundActionBox(request: _seedRequest())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.refundActionBoxReject).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.refundActionBoxRejectTitle), findsOneWidget);
      // Confirm button starts disabled (reason required).
      final confirmButton = tester.widget<TextButton>(
        find
            .ancestor(
              of: find.text(AppStrings.refundActionBoxReject).last,
              matching: find.byType(TextButton),
            )
            .first,
      );
      expect(confirmButton.onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, '정책상 환불 불가');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.refundActionBoxReject).last);
      await tester.pumpAndSettle();

      expect(fakeRepo.rejectCalls, 1);
      expect(fakeRepo.lastRejectReason, '정책상 환불 불가');
      expect(
        find.text(AppStrings.refundActionBoxRejectSuccess),
        findsOneWidget,
      );
    });
  });
}
