import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_urgency.dart';

void main() {
  Subscription sub({
    SubscriptionType type = SubscriptionType.package,
    int? totalLessons = 8,
    int usedLessons = 0,
    DateTime? endDate,
    SubscriptionStatus status = SubscriptionStatus.active,
    bool paymentConfirmed = true,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'sub',
      studentId: 's1',
      membershipId: 'cm',
      type: type,
      totalLessons: totalLessons,
      usedLessons: usedLessons,
      startDate: now,
      endDate: endDate ?? now.add(const Duration(days: 30)),
      amount: 100000,
      status: status,
      createdAt: now,
      paymentConfirmed: paymentConfirmed,
    );
  }

  group('badgeUrgency', () {
    test('미수금(postpaid 미확인) → unpaid', () {
      expect(
        sub(paymentConfirmed: false).badgeUrgency,
        SubscriptionUrgency.unpaid,
      );
    });

    test('status==expired → expired', () {
      expect(
        sub(status: SubscriptionStatus.expired).badgeUrgency,
        SubscriptionUrgency.expired,
      );
    });

    test('monthly + 만료일 경과(daysUntilExpiration<=0) → expired (표시 규칙 병합)', () {
      // 엔티티 isExpired 는 endDate<now 기준이라 "오늘 만료"는 미포착하지만,
      // 배지 규칙은 monthly 의 daysUntilExpiration<=0 을 만료로 본다.
      final s = sub(
        type: SubscriptionType.monthly,
        totalLessons: null,
        endDate: DateTime.now(),
      );
      expect(s.isBadgeExpired, isTrue);
      expect(s.badgeUrgency, SubscriptionUrgency.expired);
    });

    test('만료 임박(D-3) → expiringSoon', () {
      expect(
        sub(endDate: DateTime.now().add(const Duration(days: 3))).badgeUrgency,
        SubscriptionUrgency.expiringSoon,
      );
    });

    test('정상(여유) → normal', () {
      expect(sub().badgeUrgency, SubscriptionUrgency.normal);
    });

    test('우선순위: enum index 가 미수금<만료<임박<정상 순', () {
      expect(SubscriptionUrgency.unpaid.index, 0);
      expect(SubscriptionUrgency.expired.index, 1);
      expect(SubscriptionUrgency.expiringSoon.index, 2);
      expect(SubscriptionUrgency.normal.index, 3);
    });
  });
}
