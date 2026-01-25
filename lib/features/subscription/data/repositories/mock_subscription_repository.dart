import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Mock implementation of SubscriptionRepository for development.
class MockSubscriptionRepository implements SubscriptionRepository {
  final _uuid = const Uuid();
  final List<Subscription> _subscriptions = [];
  final List<SubscriptionUsage> _usages = [];
  final _controller = StreamController<List<Subscription>>.broadcast();

  MockSubscriptionRepository() {
    _initMockData();
    _initMockUsageData();
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
        endDate: now.subtract(const Duration(days: 1)),
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
  Future<Subscription> useLesson(String id, {String? lessonId, String? teacherName, String? instrument}) async {
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

    // Create usage record
    final usage = SubscriptionUsage(
      id: _uuid.v4(),
      subscriptionId: id,
      lessonId: lessonId,
      usedAt: DateTime.now(),
      teacherName: teacherName,
      instrument: instrument,
      note: '$newUsedLessons회차 레슨',
      createdAt: DateTime.now(),
    );
    _usages.add(usage);

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

  // ═══════════════════════════════════════════════════════════════════
  // Usage History Implementation
  // ═══════════════════════════════════════════════════════════════════

  void _initMockUsageData() {
    final now = DateTime.now();

    // Generate usage history for all subscriptions with usedLessons > 0
    _usages.addAll([
      // ═══════════════════════════════════════════════════════════════════
      // sub_trial_02: 1 lesson used (체험 완료)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_trial_02_1',
        subscriptionId: 'sub_trial_02',
        usedAt: now.subtract(const Duration(days: 2)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '체험 레슨',
        createdAt: now.subtract(const Duration(days: 2)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_01: 2 lessons used (월정액 이용중)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m01_1',
        subscriptionId: 'sub_monthly_01',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_m01_2',
        subscriptionId: 'sub_monthly_01',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_02: 3 lessons used (월정액 만료 임박)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m02_1',
        subscriptionId: 'sub_monthly_02',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_m02_2',
        subscriptionId: 'sub_monthly_02',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_m02_3',
        subscriptionId: 'sub_monthly_02',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_03: 4 lessons used (월정액 횟수 소진)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m03_1',
        subscriptionId: 'sub_monthly_03',
        usedAt: now.subtract(const Duration(days: 28)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      SubscriptionUsage(
        id: 'usage_m03_2',
        subscriptionId: 'sub_monthly_03',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_m03_3',
        subscriptionId: 'sub_monthly_03',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_m03_4',
        subscriptionId: 'sub_monthly_03',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_04: 4 lessons used (월정액 만료됨 - 지난달)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m04_1',
        subscriptionId: 'sub_monthly_04',
        usedAt: now.subtract(const Duration(days: 58)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 58)),
      ),
      SubscriptionUsage(
        id: 'usage_m04_2',
        subscriptionId: 'sub_monthly_04',
        usedAt: now.subtract(const Duration(days: 51)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 51)),
      ),
      SubscriptionUsage(
        id: 'usage_m04_3',
        subscriptionId: 'sub_monthly_04',
        usedAt: now.subtract(const Duration(days: 44)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 44)),
      ),
      SubscriptionUsage(
        id: 'usage_m04_4',
        subscriptionId: 'sub_monthly_04',
        usedAt: now.subtract(const Duration(days: 37)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 37)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_05: 1 lesson used (월정액 보너스 +1)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m05_1',
        subscriptionId: 'sub_monthly_05',
        usedAt: now.subtract(const Duration(days: 5)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 5)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_01: 3 lessons used (회차권 이용중)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p01_1',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 18)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      SubscriptionUsage(
        id: 'usage_p01_2',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 11)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      SubscriptionUsage(
        id: 'usage_p01_3',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 4)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_02: 6 lessons used (회차권 만료 임박)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p02_1',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 42)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_2',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 35)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_3',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 28)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_4',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_5',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '5회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_6',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '6회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_03: 4 lessons used (회차권 소진됨)
      // startDate: now-90일, endDate: now-30일
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p03_1',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 85)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 85)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_2',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 70)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 70)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_3',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 55)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 55)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_4',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 40)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 40)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_04: 4 lessons used (회차권 기간 만료, 미사용분 있음)
      // startDate: now-120일, endDate: now-60일
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p04_1',
        subscriptionId: 'sub_package_04',
        usedAt: now.subtract(const Duration(days: 115)),
        teacherName: '정선생',
        instrument: '클라리넷',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 115)),
      ),
      SubscriptionUsage(
        id: 'usage_p04_2',
        subscriptionId: 'sub_package_04',
        usedAt: now.subtract(const Duration(days: 100)),
        teacherName: '정선생',
        instrument: '클라리넷',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 100)),
      ),
      SubscriptionUsage(
        id: 'usage_p04_3',
        subscriptionId: 'sub_package_04',
        usedAt: now.subtract(const Duration(days: 85)),
        teacherName: '정선생',
        instrument: '클라리넷',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 85)),
      ),
      SubscriptionUsage(
        id: 'usage_p04_4',
        subscriptionId: 'sub_package_04',
        usedAt: now.subtract(const Duration(days: 70)),
        teacherName: '정선생',
        instrument: '클라리넷',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 70)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_05: 2 lessons used (회차권 일시정지)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p05_1',
        subscriptionId: 'sub_package_05',
        usedAt: now.subtract(const Duration(days: 25)),
        teacherName: '한선생',
        instrument: '오보에',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      SubscriptionUsage(
        id: 'usage_p05_2',
        subscriptionId: 'sub_package_05',
        usedAt: now.subtract(const Duration(days: 18)),
        teacherName: '한선생',
        instrument: '오보에',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 18)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_06: 3 lessons used (회차권 대량 구매 보너스)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p06_1',
        subscriptionId: 'sub_package_06',
        usedAt: now.subtract(const Duration(days: 12)),
        teacherName: '윤선생',
        instrument: '비올라',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      SubscriptionUsage(
        id: 'usage_p06_2',
        subscriptionId: 'sub_package_06',
        usedAt: now.subtract(const Duration(days: 8)),
        teacherName: '윤선생',
        instrument: '비올라',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      SubscriptionUsage(
        id: 'usage_p06_3',
        subscriptionId: 'sub_package_06',
        usedAt: now.subtract(const Duration(days: 4)),
        teacherName: '윤선생',
        instrument: '비올라',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_07: 7 lessons used (회차권 갱신 권장)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p07_1',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 49)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 49)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_2',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 42)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_3',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 35)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_4',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 28)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_5',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '5회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_6',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '6회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_p07_7',
        subscriptionId: 'sub_package_07',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '조선생',
        instrument: '트럼펫',
        note: '7회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ]);
  }

  @override
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _usages
        .where((u) => u.subscriptionId == subscriptionId)
        .toList()
      ..sort((a, b) => b.usedAt.compareTo(a.usedAt)); // Newest first
  }

  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newUsage = usage.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _usages.add(newUsage);
    return newUsage;
  }

  void dispose() {
    _controller.close();
  }
}
