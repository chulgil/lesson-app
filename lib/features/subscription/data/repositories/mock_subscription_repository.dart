import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Mock implementation of SubscriptionRepository for development.
class MockSubscriptionRepository implements SubscriptionRepository {
  final _uuid = const Uuid();
  final List<Subscription> _subscriptions = [];
  final _controller = StreamController<List<Subscription>>.broadcast();

  MockSubscriptionRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _subscriptions.addAll([
      // ═══════════════════════════════════════════════════════════════════
      // 📌 1. 체험 (Trial)
      // ═══════════════════════════════════════════════════════════════════

      // [1-1] 체험 대기
      Subscription(
        id: 'sub_trial_01',
        studentId: 'student_4',
        membershipId: 'cm_004',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        amount: 50000,
        status: SubscriptionStatus.active,
        createdAt: now,
      ),
      // 표시: "체험중" / ~1/31까지

      // [1-2] 체험 완료
      Subscription(
        id: 'sub_trial_02',
        studentId: 'student_5',
        membershipId: 'cm_010',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        amount: 30000, // Discounted
        status: SubscriptionStatus.expired,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      // 표시: "체험 완료"

      // [1-3] 무료 체험
      Subscription(
        id: 'sub_trial_03',
        studentId: 'student_6',
        membershipId: 'cm_011',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        amount: 0, // Free
        status: SubscriptionStatus.active,
        createdAt: now,
      ),
      // 표시: "체험중" (무료)

      // ═══════════════════════════════════════════════════════════════════
      // 📌 2. 월정액 (Monthly) - 미사용분 소멸
      // ═══════════════════════════════════════════════════════════════════

      // [2-1] 월정액 4회 - 이용중 (여유)
      Subscription(
        id: 'sub_monthly_01',
        studentId: 'student_1',
        membershipId: 'cm_005',
        paymentId: 'pay_002',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 2,
        startDate: monthStart,
        endDate: monthEnd,
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 27,
        fifthWeekPolicy: FifthWeekPolicy.bonus,
        createdAt: monthStart,
      ),
      // 표시: "2/4회 남음 (D-15)" ⚠️ 미사용분 소멸

      // [2-2] 월정액 4회 - 만료 임박 (1회 남음, D-3)
      Subscription(
        id: 'sub_monthly_02',
        studentId: 'student_3',
        membershipId: 'cm_003',
        paymentId: 'pay_004',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 3,
        startDate: monthStart,
        endDate: now.add(const Duration(days: 3)),
        amount: 250000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.monthly,
        billingDay: 1,
        fifthWeekPolicy: FifthWeekPolicy.skip,
        createdAt: monthStart,
      ),
      // 표시: "⚠️ 1/4회 남음 (D-3)"

      // [2-3] 월정액 4회 - 전체 사용 (횟수 소진, 기간 남음)
      Subscription(
        id: 'sub_monthly_03',
        studentId: 'student_7',
        membershipId: 'cm_012',
        paymentId: 'pay_007',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 4,
        startDate: monthStart,
        endDate: now.add(const Duration(days: 10)),
        amount: 200000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.monthly,
        billingDay: 27,
        createdAt: monthStart,
      ),
      // 표시: "0/4회 남음 (D-10)" ✅ 이번 달 모두 사용

      // [2-4] 월정액 4회 - 만료됨 (기간 종료)
      Subscription(
        id: 'sub_monthly_04',
        studentId: 'student_3',
        membershipId: 'cm_003',
        paymentId: 'pay_005',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 4,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month, 0, 23, 59, 59),
        amount: 250000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.monthly,
        billingDay: 1,
        createdAt: DateTime(now.year, now.month - 1, 1),
      ),
      // 표시: "0/4회 남음 (만료됨)" - 2024년 12월분

      // [2-5] 월정액 4회 - 미사용 소멸 (2회 남기고 만료)
      Subscription(
        id: 'sub_monthly_05',
        studentId: 'student_8',
        membershipId: 'cm_013',
        paymentId: 'pay_008',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 2,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month, 0, 23, 59, 59),
        amount: 180000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.monthly,
        billingDay: 15,
        createdAt: DateTime(now.year, now.month - 1, 1),
      ),
      // 표시: "❌ 2/4회 미사용 소멸"

      // [2-6] 월정액 8회 - 이용중 (주 2회)
      Subscription(
        id: 'sub_monthly_06',
        studentId: 'student_9',
        membershipId: 'cm_014',
        paymentId: 'pay_009',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 8,
        usedLessons: 3,
        startDate: monthStart,
        endDate: now.add(const Duration(days: 20)),
        amount: 350000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 27,
        fifthWeekPolicy: FifthWeekPolicy.bonus,
        createdAt: monthStart,
      ),
      // 표시: "5/8회 남음 (D-20)"

      // [2-7] 🆕 월정액 5주차 보너스 (+1회)
      Subscription(
        id: 'sub_monthly_07',
        studentId: 'student_1',
        membershipId: 'cm_015',
        paymentId: 'pay_010',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 1,
        bonusCount: 1,
        bonusReason: '5주차',
        startDate: monthStart,
        endDate: now.add(const Duration(days: 25)),
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 27,
        fifthWeekPolicy: FifthWeekPolicy.bonus,
        createdAt: monthStart,
      ),
      // 표시: "4/5회 남음 (D-25)" + "🎁 +1회 (5주차)"

      // [2-8] 🆕 월정액 이벤트 보너스 (+2회)
      Subscription(
        id: 'sub_monthly_08',
        studentId: 'student_10',
        membershipId: 'cm_016',
        paymentId: 'pay_011',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 0,
        bonusCount: 2,
        bonusReason: '신규 가입 이벤트',
        startDate: monthStart,
        endDate: monthEnd,
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 1,
        createdAt: monthStart,
      ),
      // 표시: "6/6회 남음" + "🎁 +2회 (신규 가입 이벤트)"

      // ═══════════════════════════════════════════════════════════════════
      // 📌 3. 회차권 (Package) - 유효기간 내 이월 가능
      // ═══════════════════════════════════════════════════════════════════

      // [3-1] 4회권 - 이용중
      Subscription(
        id: 'sub_package_01',
        studentId: 'student_11',
        membershipId: 'cm_017',
        paymentId: 'pay_012',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 3,
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.add(const Duration(days: 30)),
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      // 표시: "1/4회 남음 (D-30)" ✅ 유효기간 내 이월 가능

      // [3-2] 8회권 - 이용중 (여유)
      Subscription(
        id: 'sub_package_02',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_001',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 3,
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now.add(const Duration(days: 41)),
        amount: 380000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      // 표시: "5/8회 남음 (D-41)"

      // [3-3] 8회권 - 만료 임박 (2회 남음)
      Subscription(
        id: 'sub_package_03',
        studentId: 'student_2',
        membershipId: 'cm_002',
        paymentId: 'pay_003',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 6,
        startDate: now.subtract(const Duration(days: 45)),
        endDate: now.add(const Duration(days: 15)),
        amount: 380000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      // 표시: "⚠️ 2/8회 남음 (D-15)"

      // [3-4] 8회권 - 만료 임박 (기간 D-5)
      Subscription(
        id: 'sub_package_04',
        studentId: 'student_12',
        membershipId: 'cm_018',
        paymentId: 'pay_013',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        startDate: now.subtract(const Duration(days: 55)),
        endDate: now.add(const Duration(days: 5)),
        amount: 340000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 55)),
      ),
      // 표시: "⚠️ 4/8회 남음 (D-5)" 유효기간 만료 임박!

      // [3-5] 4회권 - 소진됨
      Subscription(
        id: 'sub_package_05',
        studentId: 'student_2',
        membershipId: 'cm_002',
        paymentId: 'pay_old',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 4,
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now.subtract(const Duration(days: 30)),
        amount: 200000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      // 표시: "0/4회 남음 (소진됨)"

      // [3-6] 8회권 - 기간 만료 (미사용분 있음)
      Subscription(
        id: 'sub_package_06',
        studentId: 'student_13',
        membershipId: 'cm_019',
        paymentId: 'pay_014',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
        startDate: now.subtract(const Duration(days: 120)),
        endDate: now.subtract(const Duration(days: 60)),
        amount: 380000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      // 표시: "⏱️ 4/8회 미사용 만료"

      // [3-7] 16회권 - 이용중 (대량)
      Subscription(
        id: 'sub_package_07',
        studentId: 'student_14',
        membershipId: 'cm_020',
        paymentId: 'pay_015',
        type: SubscriptionType.package,
        totalLessons: 16,
        usedLessons: 5,
        startDate: now.subtract(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 75)),
        amount: 700000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      // 표시: "11/16회 남음 (D-75)"

      // [3-8] 8회권 - 일시정지
      Subscription(
        id: 'sub_package_08',
        studentId: 'student_4',
        membershipId: 'cm_006',
        paymentId: 'pay_006',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 2,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 30)),
        amount: 380000,
        status: SubscriptionStatus.paused,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // 표시: "⏸️ 6/8회 남음 (일시정지)"

      // [3-9] 🆕 8회권 + 보너스 (추천 이벤트)
      Subscription(
        id: 'sub_package_09',
        studentId: 'student_15',
        membershipId: 'cm_021',
        paymentId: 'pay_016',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 2,
        bonusCount: 1,
        bonusReason: '친구 추천',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 50)),
        amount: 380000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      // 표시: "7/9회 남음 (D-50)" + "🎁 +1회 (친구 추천)"

      // [3-10] 🆕 10회권 + 1회 보너스 (대량 구매 정책) - student_1용
      Subscription(
        id: 'sub_package_10',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_017',
        type: SubscriptionType.package,
        totalLessons: 10,
        usedLessons: 3,
        bonusCount: 1,
        bonusReason: '대량 구매 보너스',
        startDate: now.subtract(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 56)),
        amount: 450000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      // 표시: "8/11회 남음 (D-56)" + "🎁 +1회 (대량 구매 보너스)"

      // [3-11] 🆕 16회권 + 2회 보너스 (대량 구매 정책) - student_1용
      Subscription(
        id: 'sub_package_11',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_018',
        type: SubscriptionType.package,
        totalLessons: 16,
        usedLessons: 4,
        bonusCount: 2,
        bonusReason: '대량 구매 보너스',
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now.add(const Duration(days: 69)),
        amount: 720000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      // 표시: "14/18회 남음 (D-69)" + "🎁 +2회 (대량 구매 보너스)"

      // [3-12] 🆕 갱신 권장 테스트 - 잔여 1회 (student_1용)
      Subscription(
        id: 'sub_package_12',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_019',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 7,
        bonusCount: 0,
        startDate: now.subtract(const Duration(days: 50)),
        endDate: now.add(const Duration(days: 10)),
        amount: 380000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      // 표시: "⚠️ 1/8회 남음 (D-10)" - 갱신 권장
    ]);
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_subscriptions));
  }

  @override
  Future<List<Subscription>> getByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _subscriptions
        .where((s) => s.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _subscriptions.firstWhere(
        (s) =>
            s.membershipId == membershipId &&
            (s.status == SubscriptionStatus.active ||
                s.status == SubscriptionStatus.expiringSoon),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Subscription?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _subscriptions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newSubscription = subscription.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _subscriptions.add(newSubscription);
    _notifyListeners();
    return newSubscription;
  }

  @override
  Future<Subscription> update(Subscription subscription) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index == -1) {
      throw Exception('Subscription not found: ${subscription.id}');
    }
    final updated = subscription.copyWith(updatedAt: DateTime.now());
    _subscriptions[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<Subscription> useLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Subscription not found: $id');
    }

    final subscription = _subscriptions[index];
    final newUsedLessons = subscription.usedLessons + 1;

    // Calculate new status based on type (hybrid model)
    SubscriptionStatus newStatus = subscription.status;

    if (subscription.type == SubscriptionType.package &&
        subscription.totalLessons != null) {
      // Package: check total lessons + bonus
      final remaining =
          subscription.totalLessons! + subscription.bonusCount - newUsedLessons;
      if (remaining <= 0) {
        newStatus = SubscriptionStatus.expired;
      } else if (remaining <= 2) {
        newStatus = SubscriptionStatus.expiringSoon;
      }
    } else if (subscription.type == SubscriptionType.monthly &&
        subscription.lessonsPerMonth != null) {
      // Monthly: check lessons per month + bonus
      final remaining = subscription.lessonsPerMonth! +
          subscription.bonusCount -
          newUsedLessons;
      if (remaining <= 0) {
        // All monthly lessons used - can still be active if days remain
        newStatus = SubscriptionStatus.expiringSoon;
      } else if (remaining <= 1) {
        newStatus = SubscriptionStatus.expiringSoon;
      }
    } else if (subscription.type == SubscriptionType.trial) {
      // Trial: single use
      if (newUsedLessons >= 1) {
        newStatus = SubscriptionStatus.expired;
      }
    }

    final updated = subscription.copyWith(
      usedLessons: newUsedLessons,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    _subscriptions[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Subscription not found: $id');
    }
    _subscriptions[index] = _subscriptions[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<List<Subscription>> getExpiringSoon() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return _subscriptions.where((s) {
      if (s.status == SubscriptionStatus.expired ||
          s.status == SubscriptionStatus.paused) {
        return false;
      }
      // Check date expiration (within 7 days)
      if (s.endDate != null && s.endDate!.difference(now).inDays <= 7) {
        return true;
      }
      // Check lesson count (2 or less remaining)
      final remaining = s.remainingLessons;
      if (remaining != null && remaining <= 2) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) async {
    // In real implementation, this would join with memberships and classes
    // For mock, we return subscriptions for known memberships
    await Future.delayed(const Duration(milliseconds: 100));
    // For teacher_1, return all subscriptions with memberships in their classes
    final teacherMembershipIds = [
      'cm_001',
      'cm_002',
      'cm_003',
      'cm_004',
      'cm_005',
      'cm_006',
      'cm_015',
    ];
    return _subscriptions
        .where((s) => teacherMembershipIds.contains(s.membershipId))
        .toList();
  }

  /// Add bonus to a subscription.
  Future<Subscription> addBonus(
      String id, int bonusCount, String reason) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Subscription not found: $id');
    }
    final subscription = _subscriptions[index];
    final updated = subscription.copyWith(
      bonusCount: subscription.bonusCount + bonusCount,
      bonusReason: reason,
      updatedAt: DateTime.now(),
    );
    _subscriptions[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Stream<List<Subscription>> watchByStudentId(String studentId) {
    Future.microtask(() async {
      final subscriptions = await getByStudentId(studentId);
      if (!_controller.isClosed) {
        _controller.add(subscriptions);
      }
    });
    return _controller.stream.map(
      (list) => list.where((s) => s.studentId == studentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Stream<Subscription?> watchActiveByMembershipId(String membershipId) {
    Future.microtask(() async {
      await getActiveByMembershipId(membershipId);
      if (!_controller.isClosed) {
        _notifyListeners();
      }
    });
    return _controller.stream.map((list) {
      try {
        return list.firstWhere(
          (s) =>
              s.membershipId == membershipId &&
              (s.status == SubscriptionStatus.active ||
                  s.status == SubscriptionStatus.expiringSoon),
        );
      } catch (_) {
        return null;
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
