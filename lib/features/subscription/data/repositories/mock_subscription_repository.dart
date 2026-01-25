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
      // 📌 1. 체험 (Trial) - 2 cases
      // ═══════════════════════════════════════════════════════════════════

      // [1] 체험 대기 (active)
      Subscription(
        id: 'sub_trial_01',
        studentId: 'student_1',
        membershipId: 'cm_001',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        amount: 50000,
        status: SubscriptionStatus.active,
        createdAt: now,
      ),

      // [2] 체험 완료 (expired)
      Subscription(
        id: 'sub_trial_02',
        studentId: 'student_1',
        membershipId: 'cm_001',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        amount: 30000,
        status: SubscriptionStatus.expired,
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // 📌 2. 월정액 (Monthly) - 5 cases
      // ═══════════════════════════════════════════════════════════════════

      // [3] 월정액 - 이용중 (active)
      Subscription(
        id: 'sub_monthly_01',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_001',
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

      // [4] 월정액 - 만료 임박 (expiringSoon, 횟수 부족)
      Subscription(
        id: 'sub_monthly_02',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_002',
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

      // [5] 월정액 - 횟수 소진, 기간 남음 (expiringSoon, 0회)
      Subscription(
        id: 'sub_monthly_03',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_003',
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

      // [6] 월정액 - 만료됨 (expired)
      Subscription(
        id: 'sub_monthly_04',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_004',
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

      // [7] 월정액 - 보너스 (+1회)
      Subscription(
        id: 'sub_monthly_05',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_005',
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

      // ═══════════════════════════════════════════════════════════════════
      // 📌 3. 회차권 (Package) - 7 cases
      // ═══════════════════════════════════════════════════════════════════

      // [8] 회차권 - 이용중 (active)
      Subscription(
        id: 'sub_package_01',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_006',
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

      // [9] 회차권 - 만료 임박 (expiringSoon, 2회 남음)
      Subscription(
        id: 'sub_package_02',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_007',
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

      // [10] 회차권 - 소진됨 (expired, all used)
      Subscription(
        id: 'sub_package_03',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_008',
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

      // [11] 회차권 - 기간 만료 미사용분 있음 (expired with remaining)
      Subscription(
        id: 'sub_package_04',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_009',
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

      // [12] 회차권 - 일시정지 (paused)
      Subscription(
        id: 'sub_package_05',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_010',
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

      // [13] 회차권 - 대량 구매 보너스 (+1회)
      Subscription(
        id: 'sub_package_06',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_011',
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

      // [14] 회차권 - 갱신 권장 (expiringSoon, 잔여 1회)
      Subscription(
        id: 'sub_package_07',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_012',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 7,
        startDate: now.subtract(const Duration(days: 50)),
        endDate: now.add(const Duration(days: 10)),
        amount: 380000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
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
    final teacherMembershipIds = ['cm_001'];
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
