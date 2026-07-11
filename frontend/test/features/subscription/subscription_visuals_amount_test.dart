import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_visuals.dart';

/// Regression guard (2026-07-08 FE audit D3).
///
/// trial 금액 표기가 `(amount / 10000).toStringAsFixed(0)` 로 반올림해
/// 45,000원을 "5만원"으로 오표기하던 버그의 가드. 만 단위 + 나머지를 정확히
/// 표기해야 한다 (반올림 금지). fix 를 되돌리면 RED.
Subscription _trial(int amount) => Subscription(
  id: 's1',
  studentId: 'st1',
  membershipId: 'm1',
  type: SubscriptionType.trial,
  amount: amount,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026),
);

void main() {
  test('비-라운드 trial 금액은 반올림하지 않는다 (45,000 → 4만 5000원, #D3)', () {
    final text = _trial(45000).detailText;
    expect(text, contains('4만 5000원'));
    expect(text, isNot(contains('5만원')));
  });

  test('정확히 만 단위 trial 금액은 N만원 (50,000 → 5만원, #D3)', () {
    final text = _trial(50000).detailText;
    expect(text, contains('5만원'));
  });

  test('만 미만 trial 금액은 원 단위 (9,000 → 9000원, #D3)', () {
    final text = _trial(9000).detailText;
    expect(text, contains('9000원'));
  });
}
