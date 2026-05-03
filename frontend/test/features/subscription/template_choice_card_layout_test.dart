import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/template_choice_card.dart';

void main() {
  testWidgets('template choice card lays out on narrow student screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TemplateChoiceCard(
              template: SubscriptionTemplate(
                id: 'template-long-name',
                ownerId: 'teacher-1',
                ownerType: SubscriptionTemplateOwnerType.teacher,
                name: '초중급 콩쿠르 준비 집중 패키지 12회권',
                totalLessons: 12,
                lessonDurationMinutes: 60,
                validityDays: 120,
                price: 480000,
                createdAt: DateTime.utc(2026, 5, 4),
              ),
              isRecommended: true,
              isProcessing: false,
              onAccept: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('초중급 콩쿠르 준비 집중 패키지 12회권'), findsOneWidget);
  });
}
