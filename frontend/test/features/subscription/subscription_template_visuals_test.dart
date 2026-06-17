// 수강권 템플릿 정가/할인가 표시 로직 단위 테스트.
//
// Guards SubscriptionTemplateVisualX 의 hasDiscount / discountPercent /
// formattedRegularPrice / summaryTextNoPrice — 카드·시트의 취소선 + 할인율
// 표시가 의존하는 순수 계산.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_template_visuals.dart';

SubscriptionTemplate template({required int price, int? regularPrice}) =>
    SubscriptionTemplate(
      id: 't1',
      ownerId: 'teacher-1',
      ownerType: SubscriptionTemplateOwnerType.teacher,
      name: '8회권',
      totalLessons: 8,
      lessonDurationMinutes: 50,
      validityDays: 90,
      price: price,
      regularPrice: regularPrice,
      createdAt: DateTime.utc(2026, 6, 17),
    );

void main() {
  group('SubscriptionTemplateVisualX 정가/할인', () {
    test('regularPrice 미설정 → 할인 없음 (단일가)', () {
      final t = template(price: 400000);
      expect(t.hasDiscount, isFalse);
      expect(t.discountPercent, 0);
      // 정가 fallback = 판매가.
      expect(t.formattedRegularPrice, t.formattedPrice);
    });

    test('regularPrice <= price → 할인 없음', () {
      expect(
        template(price: 400000, regularPrice: 400000).hasDiscount,
        isFalse,
      );
      expect(
        template(price: 400000, regularPrice: 300000).hasDiscount,
        isFalse,
      );
    });

    test('regularPrice > price → 할인 표시 + 반올림 할인율', () {
      final t = template(price: 400000, regularPrice: 500000);
      expect(t.hasDiscount, isTrue);
      expect(t.discountPercent, 20); // (500000-400000)/500000 = 20%
      expect(t.formattedRegularPrice, '50만원');
      expect(t.formattedPrice, '40만원');
    });

    test('할인율 반올림 (33.3% → 33)', () {
      final t = template(price: 200000, regularPrice: 300000);
      expect(t.discountPercent, 33);
    });

    test('summaryTextNoPrice 는 가격을 포함하지 않는다', () {
      final t = template(price: 400000, regularPrice: 500000);
      expect(t.summaryTextNoPrice, '8회 · 50분');
      expect(t.summaryTextNoPrice.contains('원'), isFalse);
    });
  });
}
