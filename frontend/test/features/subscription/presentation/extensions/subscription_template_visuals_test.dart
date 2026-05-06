import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_template_visuals.dart';

void main() {
  group('SubscriptionTemplateVisualX', () {
    final template = SubscriptionTemplate(
      id: 'template_1',
      ownerId: 'teacher_1',
      ownerType: SubscriptionTemplateOwnerType.teacher,
      name: '기본 패키지',
      totalLessons: 8,
      lessonDurationMinutes: 50,
      validityDays: 90,
      price: 400000,
      createdAt: DateTime(2026),
    );

    test('formats price labels', () {
      expect(template.formattedPrice, '40만원');
      expect(template.formattedPricePerLesson, '5만원');
    });

    test('formats validity and summary labels', () {
      expect(template.formattedValidity, '3개월');
      expect(template.summaryText, '8회 · 50분 · 40만원');
    });
  });
}
