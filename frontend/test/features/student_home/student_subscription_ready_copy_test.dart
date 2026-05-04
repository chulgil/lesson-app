import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/schedule_confirmation_card.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_confirmation_card_widget.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_issued_card.dart';

void main() {
  testWidgets('schedule confirmation card uses subscription ready copy', (
    tester,
  ) async {
    final card = ScheduleConfirmationCard(
      id: 'card_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      teacherName: '김선생님',
      instrument: '바이올린',
      subscriptionId: 'sub_1',
      cardType: ScheduleCardType.reEnrollment,
      createdAt: DateTime(2026, 5, 4),
      totalLessons: 8,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ScheduleConfirmationCardWidget(card: card)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('수강권이 준비됐어요'), findsOneWidget);
    expect(find.text('첫 레슨 시간을 확인해주세요'), findsOneWidget);
    expect(find.textContaining('수강권이 발급되었습니다'), findsNothing);
    expect(find.textContaining('수강권이 발행되었습니다'), findsNothing);
  });

  testWidgets('subscription issued card uses subscription ready copy', (
    tester,
  ) async {
    final subscription = Subscription(
      id: 'sub_1',
      studentId: 'student_1',
      membershipId: 'membership_1',
      type: SubscriptionType.package,
      totalLessons: 8,
      amount: 320000,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 5, 4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionIssuedCard(subscription: subscription),
        ),
      ),
    );

    expect(find.textContaining('수강권이 준비됐어요'), findsOneWidget);
    expect(find.textContaining('수강권이 발급되었습니다'), findsNothing);
    expect(find.textContaining('수강권이 발행되었습니다'), findsNothing);
  });
}
