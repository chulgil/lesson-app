// #806 — SubscriptionCard 갱신 제안 CTA (onRenew) 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_card.dart';

Subscription _sub() => Subscription(
  id: 'sub-1',
  studentId: 'student-1',
  membershipId: 'mem-1',
  type: SubscriptionType.package,
  totalLessons: 10,
  usedLessons: 8,
  amount: 250000,
  status: SubscriptionStatus.active,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('onRenew 제공 시 갱신 제안 CTA 노출 + 탭 콜백', (tester) async {
    var renewTapped = false;
    await tester.pumpWidget(
      _host(
        SubscriptionCard(
          subscription: _sub(),
          onRenew: () => renewTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.text(AppStrings.subscriptionRenewProposeCta);
    expect(cta, findsOneWidget);

    await tester.ensureVisible(cta);
    await tester.tap(cta);
    expect(renewTapped, isTrue);
  });

  testWidgets('onRenew 미제공 시 CTA 미노출 (기존 사용처 영향 없음)', (tester) async {
    await tester.pumpWidget(_host(SubscriptionCard(subscription: _sub())));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.subscriptionRenewProposeCta), findsNothing);
  });
}
