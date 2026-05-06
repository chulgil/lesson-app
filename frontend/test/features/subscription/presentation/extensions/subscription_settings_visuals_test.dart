import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_settings.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_settings_visuals.dart';

void main() {
  group('PackageDiscountPolicyVisualX', () {
    test('maps discount policy display text', () {
      const policy = PackageDiscountPolicy(
        minLessons: 10,
        type: DiscountType.discount,
        value: 15,
      );

      expect(policy.displayText, '10회 이상: 15% 할인');
    });

    test('maps bonus lesson policy display text', () {
      const policy = PackageDiscountPolicy(
        minLessons: 16,
        type: DiscountType.bonusLessons,
        value: 2,
      );

      expect(policy.displayText, '16회 이상: +2회 무료');
    });
  });
}
