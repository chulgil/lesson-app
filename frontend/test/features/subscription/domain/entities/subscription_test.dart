import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_visuals.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helper to create test subscriptions
  // ═══════════════════════════════════════════════════════════════════════════

  Subscription createSubscription({
    SubscriptionType type = SubscriptionType.package,
    int? totalLessons,
    int? lessonsPerMonth,
    int usedLessons = 0,
    int bonusCount = 0,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus status = SubscriptionStatus.active,
    bool paymentConfirmed = true,
    DateTime? paidAt,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub',
      studentId: 'student_1',
      membershipId: 'cm_001',
      type: type,
      totalLessons: totalLessons,
      lessonsPerMonth: lessonsPerMonth,
      usedLessons: usedLessons,
      bonusCount: bonusCount,
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(const Duration(days: 30)),
      amount: 200000,
      status: status,
      createdAt: now,
      paymentConfirmed: paymentConfirmed,
      paidAt: paidAt,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // remainingLessons tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('remainingLessons', () {
    group('Package type', () {
      test('8회권, 0회 사용 → 8회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 0,
        );
        expect(sub.remainingLessons, 8);
      });

      test('8회권, 4회 사용 → 4회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 4,
        );
        expect(sub.remainingLessons, 4);
      });

      test('8회권, 8회 사용 → 0회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 8,
        );
        expect(sub.remainingLessons, 0);
      });

      test('8회권 + 2회 보너스, 0회 사용 → 10회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 0,
          bonusCount: 2,
        );
        expect(sub.remainingLessons, 10);
      });

      test('8회권 + 1회 보너스, 5회 사용 → 4회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 5,
          bonusCount: 1,
        );
        expect(sub.remainingLessons, 4);
      });

      test('4회권, 4회 사용 → 0회 남음 (소진)', () {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 4,
          usedLessons: 4,
        );
        expect(sub.remainingLessons, 0);
      });
    });

    group('Monthly type', () {
      test('월정액 4회, 0회 사용 → 4회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          usedLessons: 0,
        );
        expect(sub.remainingLessons, 4);
      });

      test('월정액 4회, 2회 사용 → 2회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          usedLessons: 2,
        );
        expect(sub.remainingLessons, 2);
      });

      test('월정액 4회 + 1회 보너스(5주차), 3회 사용 → 2회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          usedLessons: 3,
          bonusCount: 1,
        );
        expect(sub.remainingLessons, 2);
      });
    });

    group('Trial type', () {
      test('체험 미사용 → 1회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.trial,
          totalLessons: 1,
          usedLessons: 0,
        );
        expect(sub.remainingLessons, 1);
      });

      test('체험 사용 → 0회 남음', () {
        final sub = createSubscription(
          type: SubscriptionType.trial,
          totalLessons: 1,
          usedLessons: 1,
        );
        expect(sub.remainingLessons, 0);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // totalLessonsForDisplay tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('totalLessonsForDisplay', () {
    test('Package: 8회권, 보너스 없음 → 8', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
      );
      expect(sub.totalLessonsForDisplay, 8);
    });

    test('Package: 8회권 + 2회 보너스 → 10', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        bonusCount: 2,
      );
      expect(sub.totalLessonsForDisplay, 10);
    });

    test('Monthly: 4회/월, 보너스 없음 → 4', () {
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
      );
      expect(sub.totalLessonsForDisplay, 4);
    });

    test('Monthly: 4회/월 + 1회 보너스 → 5', () {
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        bonusCount: 1,
      );
      expect(sub.totalLessonsForDisplay, 5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // baseLessons tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('baseLessons', () {
    test('Package: 8회권 → 8 (보너스 제외)', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        bonusCount: 2,
      );
      expect(sub.baseLessons, 8);
    });

    test('Monthly: 4회/월 → 4 (보너스 제외)', () {
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        bonusCount: 1,
      );
      expect(sub.baseLessons, 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // payment state tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('payment state', () {
    test('후불 발급 후 아직 입금하지 않은 활성 수강권은 미수금이다', () {
      final sub = createSubscription(paymentConfirmed: false, paidAt: null);

      expect(sub.isUnpaid, isTrue);
      expect(sub.needsPaymentConfirmation, isFalse);
      expect(sub.paymentStatusLabel, '미수금');
    });

    test('학생이 입금 완료를 알렸고 선생님이 확인 전이면 입금 확인 필요 상태다', () {
      final sub = createSubscription(
        paymentConfirmed: false,
        paidAt: DateTime(2026, 5, 5, 10),
      );

      expect(sub.isUnpaid, isFalse);
      expect(sub.needsPaymentConfirmation, isTrue);
      expect(sub.paymentStatusLabel, '입금 확인 필요');
    });

    test('선생님이 입금을 확인한 수강권은 미수금도 입금 확인 필요도 아니다', () {
      final sub = createSubscription(
        paymentConfirmed: true,
        paidAt: DateTime(2026, 5, 5, 10),
      );

      expect(sub.isUnpaid, isFalse);
      expect(sub.needsPaymentConfirmation, isFalse);
      expect(sub.paymentStatusLabel, '입금 확인 완료');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // summaryText tests (핵심: 남은횟수/전체횟수 표시)
  // ═══════════════════════════════════════════════════════════════════════════

  group('summaryText', () {
    test('Package: 8회권, 4회 사용 → "4/8회 남음 (D-30)"', () {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        endDate: now.add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
      );
      expect(sub.summaryText, contains('4/8회 남음'));
      expect(sub.summaryText, contains('D-'));
    });

    test('Package: 8회권 + 1회 보너스, 3회 사용 → "6/9회 남음"', () {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 3,
        bonusCount: 1,
        endDate: now.add(const Duration(days: 30)),
      );
      // remaining = 8 + 1 - 3 = 6
      // total = 8 + 1 = 9
      expect(sub.summaryText, contains('6/9회 남음'));
    });

    test('Package: 만료됨 상태 → "만료됨" 포함', () {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        endDate: now.subtract(const Duration(days: 30)),
        status: SubscriptionStatus.expired,
      );
      expect(sub.summaryText, contains('만료됨'));
    });

    test('Package: 횟수 소진 → "모두 사용" 포함', () {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 8,
        endDate: now.add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
      );
      expect(sub.summaryText, contains('모두 사용'));
    });

    test('Trial 체험 미사용 → "체험중"', () {
      final sub = createSubscription(
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
      );
      expect(sub.summaryText, '체험중');
    });

    test('Trial 체험 완료 → "체험 완료"', () {
      final sub = createSubscription(
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 1,
      );
      expect(sub.summaryText, '체험 완료');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // usagePercentage tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('usagePercentage', () {
    test('8회권, 0회 사용 → 0%', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 0,
      );
      expect(sub.usagePercentage, 0.0);
    });

    test('8회권, 4회 사용 → 50%', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
      );
      expect(sub.usagePercentage, 50.0);
    });

    test('8회권, 8회 사용 → 100%', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 8,
      );
      expect(sub.usagePercentage, 100.0);
    });

    test('8회권 + 2회 보너스, 5회 사용 → 50%', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 5,
        bonusCount: 2,
      );
      // total = 10, used = 5 → 50%
      expect(sub.usagePercentage, 50.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // isExpired tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('isExpired', () {
    test('status가 expired면 → true', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        status: SubscriptionStatus.expired,
      );
      expect(sub.isExpired, true);
    });

    test('endDate가 과거면 → true', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 0,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        status: SubscriptionStatus.active,
      );
      expect(sub.isExpired, true);
    });

    test('remainingLessons가 0이지만 status active → false (isDepleted와 분리)', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 4,
        status: SubscriptionStatus.active,
      );
      // isExpired는 status/endDate만 확인 (isDepleted와 분리된 개념)
      expect(sub.isExpired, false);
    });

    test('active 상태, 횟수 남음, 기간 남음 → false', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
      );
      expect(sub.isExpired, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // isExpiringSoon tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('isExpiringSoon', () {
    test('잔여 7일 이내 → true', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 2,
        endDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(sub.isExpiringSoon, true);
    });

    test('잔여 1회 → true (단일 경고 상태)', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 7,
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(sub.isExpiringSoon, true);
    });

    test('잔여 3회, 15일 남음 → false', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 5,
        endDate: DateTime.now().add(const Duration(days: 15)),
      );
      expect(sub.isExpiringSoon, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // daysUntilExpiration tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('daysUntilExpiration', () {
    test('30일 후 만료 → 29~30 (시간대에 따라 다름)', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      // Allow for timezone/time-of-day variance
      expect(sub.daysUntilExpiration, inInclusiveRange(29, 30));
    });

    test('1일 전 만료 → -2~-1 (시간대에 따라 다름)', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sub.daysUntilExpiration, inInclusiveRange(-2, -1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // hasBonus tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('hasBonus', () {
    test('bonusCount > 0 → true', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        bonusCount: 1,
      );
      expect(sub.hasBonus, true);
    });

    test('bonusCount = 0 → false', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        bonusCount: 0,
      );
      expect(sub.hasBonus, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // typeLabel tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('typeLabel', () {
    test('체험 → "체험"', () {
      final sub = createSubscription(type: SubscriptionType.trial);
      expect(sub.typeLabel, '체험');
    });

    test('월정액 4회 → "월정액 (4회)"', () {
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
      );
      expect(sub.typeLabel, '월정액 (4회)');
    });

    test('회차권 8회 → "8회권"', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
      );
      expect(sub.typeLabel, '8회권');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // statusLabel tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('statusLabel', () {
    test('active → "이용중"', () {
      final sub = createSubscription(status: SubscriptionStatus.active);
      expect(sub.statusLabel, '이용중');
    });

    test('expiringSoon → "만료 임박"', () {
      final sub = createSubscription(status: SubscriptionStatus.expiringSoon);
      expect(sub.statusLabel, '만료 임박');
    });

    test('expired → "만료됨"', () {
      final sub = createSubscription(status: SubscriptionStatus.expired);
      expect(sub.statusLabel, '만료됨');
    });

    test('paused → "일시정지"', () {
      final sub = createSubscription(status: SubscriptionStatus.paused);
      expect(sub.statusLabel, '일시정지');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 버그 재현: 8/4회 표시 문제
  // ═══════════════════════════════════════════════════════════════════════════

  group('Bug: 8/4회 표시 문제 재현', () {
    test('remaining은 항상 total 이하여야 함', () {
      // 모든 가능한 조합에서 remaining <= total 검증
      for (int total = 1; total <= 20; total++) {
        for (int used = 0; used <= total + 5; used++) {
          for (int bonus = 0; bonus <= 5; bonus++) {
            final sub = createSubscription(
              type: SubscriptionType.package,
              totalLessons: total,
              usedLessons: used,
              bonusCount: bonus,
            );

            final remaining = sub.remainingLessons;
            final totalDisplay = sub.totalLessonsForDisplay;

            if (remaining != null && totalDisplay != null) {
              // remaining should never exceed totalDisplay
              expect(
                remaining <= totalDisplay,
                true,
                reason:
                    'remaining($remaining) > total($totalDisplay) for total=$total, used=$used, bonus=$bonus',
              );
            }
          }
        }
      }
    });

    test('summaryText에서 remaining이 total을 초과하면 안됨', () {
      // 8/4회 같은 표시가 나오면 안됨
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 0,
        bonusCount: 0,
      );
      final text = sub.summaryText;
      // "4/4회 남음" 형태여야 함
      expect(text, contains('4/4회 남음'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Edge cases
  // ═══════════════════════════════════════════════════════════════════════════

  group('Edge cases', () {
    test('usedLessons > totalLessons 시 remainingLessons가 음수', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 6, // 비정상: 사용 > 전체
      );
      expect(sub.remainingLessons, -2);
    });

    test('totalLessons가 null이면 remainingLessons도 null', () {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: null,
        usedLessons: 0,
      );
      expect(sub.remainingLessons, null);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 만료 상태 vs 실제 잔여 횟수 불일치 검증
  // ═══════════════════════════════════════════════════════════════════════════

  group('만료 상태와 잔여 횟수 일관성', () {
    test('status=expired 이지만 remainingLessons > 0인 경우 (기간만료)', () {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        endDate: now.subtract(const Duration(days: 60)), // 기간 만료
        status: SubscriptionStatus.expired,
      );

      // 횟수는 4회 남음
      expect(sub.remainingLessons, 4);
      // 하지만 만료 상태
      expect(sub.status, SubscriptionStatus.expired);
      // isExpired도 true
      expect(sub.isExpired, true);
      // summaryText에는 "만료됨" 표시
      expect(sub.summaryText, contains('만료됨'));
      // 미사용 잔여 횟수 표시: "4회 미사용 (만료됨)"
      expect(sub.summaryText, contains('4회 미사용'));
    });
  });

  group('instrument (membership SSOT)', () {
    Subscription baseSub({String? instrument}) => Subscription(
      id: 's1',
      studentId: 'st1',
      membershipId: 'm1',
      instrument: instrument,
      type: SubscriptionType.package,
      totalLessons: 8,
      amount: 100000,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    test('toJson은 instrument를 BE 키로 직렬화한다', () {
      expect(baseSub(instrument: '피아노').toJson()['instrument'], '피아노');
    });

    test('toJson → fromJson round-trip에서 instrument가 보존된다', () {
      final restored = Subscription.fromJson(
        baseSub(instrument: '바이올린').toJson(),
      );
      expect(restored.instrument, '바이올린');
    });

    test('instrument가 null이면 round-trip 후에도 null이다 (레거시 호환)', () {
      final restored = Subscription.fromJson(baseSub().toJson());
      expect(restored.instrument, isNull);
    });
  });
}
