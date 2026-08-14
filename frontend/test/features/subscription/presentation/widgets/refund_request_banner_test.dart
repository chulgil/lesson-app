// 중복 요청 차단 UI + 역할별 표면 선택 — #1271.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/presentation/providers/lesson_class_providers.dart';
import 'package:lessonaza/features/students/presentation/providers/membership_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/lesson_policy_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/refund_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_request_banner.dart';

Subscription _subscription() {
  return Subscription(
    id: 'sub_1',
    studentId: 'student_1',
    membershipId: 'membership_1',
    type: SubscriptionType.package,
    totalLessons: 8,
    usedLessons: 1,
    amount: 400000,
    status: SubscriptionStatus.active,
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );
}

RefundRequest _pendingRequest() {
  return RefundRequest(
    id: 'refund_1',
    subscriptionId: 'sub_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    bankName: '신한은행',
    accountNumber: '110-123-456789',
    accountHolder: '홍길동',
    requestedAt: DateTime(2026, 8, 14),
  );
}

List<Override> _fixtureOverrides() {
  return [
    membershipProvider('membership_1').overrideWith(
      (ref) async => ClassMembership(
        id: 'membership_1',
        lessonClassId: 'class_1',
        studentId: 'student_1',
        instrument: '피아노',
        status: MembershipStatus.active,
        monthlyFee: 400000,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    lessonClassProvider('class_1').overrideWith(
      (ref) async => LessonClass(
        id: 'class_1',
        teacherId: 'teacher_1',
        name: '피아노 레슨',
        type: LessonClassType.private,
        paymentType: PaymentType.parent,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    effectivePolicyProvider(
      teacherId: 'teacher_1',
      lessonClassId: 'class_1',
    ).overrideWith((ref) async => null),
  ];
}

Widget _scoped(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('학생 — 중복 요청 차단 UI', () {
    testWidgets('요청이 없으면 환불 요청 CTA 를 보여준다', (tester) async {
      await tester.pumpWidget(
        _scoped(
          RefundRequestBanner(
            subscription: _subscription(),
            viewerRole: 'student',
            studentName: '김민수',
          ),
          [
            ..._fixtureOverrides(),
            refundRequestForSubscriptionProvider(
              subscriptionId: 'sub_1',
              asTeacher: false,
            ).overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.refundRequestCta), findsOneWidget);
      expect(find.text('환불 요청됨'), findsNothing);
    });

    testWidgets('이미 진행 중인 요청이 있으면 CTA 대신 상태 배지만 보여준다', (tester) async {
      await tester.pumpWidget(
        _scoped(
          RefundRequestBanner(
            subscription: _subscription(),
            viewerRole: 'student',
            studentName: '김민수',
          ),
          [
            ..._fixtureOverrides(),
            refundRequestForSubscriptionProvider(
              subscriptionId: 'sub_1',
              asTeacher: false,
            ).overrideWith((ref) async => _pendingRequest()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.refundRequestCta), findsNothing);
      expect(find.text('환불 요청됨'), findsOneWidget);
    });
  });

  group('선생님 — 처리 박스 표면 선택', () {
    testWidgets('처리 대기 중인 요청이 있으면 처리 박스를 보여준다', (tester) async {
      await tester.pumpWidget(
        _scoped(
          RefundRequestBanner(
            subscription: _subscription(),
            viewerRole: 'teacher',
            studentName: '김민수',
          ),
          [
            ..._fixtureOverrides(),
            refundRequestForSubscriptionProvider(
              subscriptionId: 'sub_1',
              asTeacher: true,
            ).overrideWith((ref) async => _pendingRequest()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.refundActionBoxComplete), findsOneWidget);
      expect(find.text(AppStrings.refundActionBoxReject), findsOneWidget);
      // Account info unmasked while actionable.
      expect(find.textContaining('110-123-456789'), findsOneWidget);
    });

    testWidgets('처리할 요청이 없으면 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        _scoped(
          RefundRequestBanner(
            subscription: _subscription(),
            viewerRole: 'teacher',
            studentName: '김민수',
          ),
          [
            ..._fixtureOverrides(),
            refundRequestForSubscriptionProvider(
              subscriptionId: 'sub_1',
              asTeacher: true,
            ).overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.refundActionBoxComplete), findsNothing);
    });
  });
}
