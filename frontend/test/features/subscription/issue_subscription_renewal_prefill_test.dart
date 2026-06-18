// #806 — 갱신 발급: renewFromSubscriptionId 로 이전 수강권 값이 폼에 프리필되는지 검증.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

Subscription _prev() => Subscription(
  id: 'prev-sub',
  studentId: 'student-1',
  membershipId: 'mem-1',
  type: SubscriptionType.package,
  totalLessons: 10,
  amount: 250000,
  status: SubscriptionStatus.expiringSoon,
  startDate: DateTime.utc(2026, 1, 1),
  endDate: DateTime.utc(2026, 5, 1), // 120일 (기본 90 과 구분)
  totalRescheduleAllowance: 3,
  createdAt: DateTime.utc(2026, 1, 1),
);

bool _hasTextFieldValue(WidgetTester tester, String value) {
  return tester
      .widgetList<TextFormField>(find.byType(TextFormField))
      .any((field) => field.controller?.text == value);
}

void main() {
  testWidgets('renewFromSubscriptionId 로 이전 수강권 회차·유효기간 프리필', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider('prev-sub').overrideWith((ref) => _prev()),
        ],
        child: const MaterialApp(
          home: IssueSubscriptionScreen(
            // batch 모드로 멤버십 provider 의존 회피 (프리필 로직은 모드 무관).
            studentIds: ['student-1', 'student-2'],
            renewFromSubscriptionId: 'prev-sub',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 회차 컨트롤러 10 프리필 (기본 8 과 구분).
    expect(_hasTextFieldValue(tester, '10'), isTrue);
    // 유효기간 컨트롤러 120 프리필 (기본 90 과 구분).
    expect(_hasTextFieldValue(tester, '120'), isTrue);
  });
}
