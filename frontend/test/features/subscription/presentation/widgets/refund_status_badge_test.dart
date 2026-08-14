import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_status_badge.dart';

RefundRequest _request(RefundRequestStatus status) {
  return RefundRequest(
    id: 'r1',
    subscriptionId: 'sub_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    bankName: '신한은행',
    accountNumber: '110-123-456789',
    accountHolder: '홍길동',
    status: status,
    requestedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('RefundStatusBadge — 학생 배지 상태 3종', () {
    testWidgets('requested shows 환불 요청됨', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefundStatusBadge(
              request: _request(RefundRequestStatus.requested),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('환불 요청됨'), findsOneWidget);
    });

    testWidgets('completed shows 환불 완료', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefundStatusBadge(
              request: _request(RefundRequestStatus.completed),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('환불 완료'), findsOneWidget);
    });

    testWidgets('rejected shows 환불 반려', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefundStatusBadge(
              request: _request(RefundRequestStatus.rejected),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('환불 반려'), findsOneWidget);
    });
  });
}
