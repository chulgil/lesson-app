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
      // 📌 student_1: 현실적인 시나리오 (활성 1개 + 만료 1개)
      // ═══════════════════════════════════════════════════════════════════

      // [1] 바이올린 회차권 - 이용중 (active)
      Subscription(
        id: 'sub_package_01',
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

      // [2] 바이올린 회차권 - 이전 수강권 (expired)
      Subscription(
        id: 'sub_package_02',
        studentId: 'student_1',
        membershipId: 'cm_001',
        paymentId: 'pay_002',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 4,
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now.subtract(const Duration(days: 22)),
        amount: 200000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 90)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_1: 피아노 수강권 (cm_005용)
      // ═══════════════════════════════════════════════════════════════════

      // [3] 피아노 월정액 - 이용중 (active)
      Subscription(
        id: 'sub_monthly_01',
        studentId: 'student_1',
        membershipId: 'cm_005',
        paymentId: 'pay_003',
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

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_2: 체험 완료 후 제안 대기
      // ═══════════════════════════════════════════════════════════════════

      // [4] 피아노 체험 완료 (expired)
      Subscription(
        id: 'sub_trial_01',
        studentId: 'student_2',
        membershipId: 'cm_002',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.subtract(const Duration(days: 2)),
        amount: 30000,
        status: SubscriptionStatus.expired,
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_3: 수강권 만료 임박
      // ═══════════════════════════════════════════════════════════════════

      // [5] 바이올린 회차권 - 1회 남음 (expiringSoon)
      Subscription(
        id: 'sub_package_03',
        studentId: 'student_3',
        membershipId: 'cm_003',
        paymentId: 'pay_004',
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

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_4: 체험 예정
      // ═══════════════════════════════════════════════════════════════════

      // [6] 첼로 체험 대기 (active)
      Subscription(
        id: 'sub_trial_02',
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

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_6: 수강권 확정됨 (proposal_confirmed_1 연결)
      // ═══════════════════════════════════════════════════════════════════

      // [7] 바이올린 회차권 - 확정됨 (active)
      Subscription(
        id: 'sub_1',
        studentId: 'student_6',
        membershipId: 'cm_007',
        paymentId: 'pay_005',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 0,
        startDate: now.subtract(const Duration(days: 4)),
        endDate: now.add(const Duration(days: 56)),
        amount: 380000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 4)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 5)),
        paymentConfirmedAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // 📌 student_5: 후불 발급 (미수금 테스트)
      // ═══════════════════════════════════════════════════════════════════

      // [8] 바이올린 회차권 - 후불 발급 (미수금)
      Subscription(
        id: 'sub_unpaid_01',
        studentId: 'student_5',
        membershipId: 'cm_006',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 53)),
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 7)),
        paymentConfirmed: false, // 미수금!
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
  Future<Subscription> useReschedule(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Subscription not found: $id');
    }

    final subscription = _subscriptions[index];

    // Check if reschedule is available
    if (!subscription.canReschedule) {
      throw Exception('No reschedule allowance remaining');
    }

    final updated = subscription.copyWith(
      usedRescheduleCount: subscription.usedRescheduleCount + 1,
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

  // ═══════════════════════════════════════════════════════════════════
  // Payment Implementation
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // In real impl, filter by teacherId via membership/class join
    return _subscriptions.where((s) => s.isUnpaid).toList();
  }

  @override
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Subscription not found: $id');
    }

    final now = DateTime.now();
    final updated = _subscriptions[index].copyWith(
      paymentConfirmed: true,
      paymentMethod: paymentMethod,
      paidAt: now,
      paymentConfirmedAt: now,
      updatedAt: now,
    );
    _subscriptions[index] = updated;
    _notifyListeners();
    return updated;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Usage History Implementation
  // ═══════════════════════════════════════════════════════════════════

  void _initMockUsageData() {
    final now = DateTime.now();

    // Generate usage history matching new subscription data
    _usages.addAll([
      // ═══════════════════════════════════════════════════════════════════
      // sub_package_01: 3 lessons used (student_1, 바이올린 회차권 이용중)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p01_1',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 18)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      SubscriptionUsage(
        id: 'usage_p01_2',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 11)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      SubscriptionUsage(
        id: 'usage_p01_3',
        subscriptionId: 'sub_package_01',
        usedAt: now.subtract(const Duration(days: 4)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_02: 4 lessons used (student_1, 바이올린 이전 수강권)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p02_1',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 80)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 80)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_2',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 66)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 66)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_3',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 52)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 52)),
      ),
      SubscriptionUsage(
        id: 'usage_p02_4',
        subscriptionId: 'sub_package_02',
        usedAt: now.subtract(const Duration(days: 38)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 38)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_monthly_01: 2 lessons used (student_1, 피아노 월정액)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_m01_1',
        subscriptionId: 'sub_monthly_01',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_m01_2',
        subscriptionId: 'sub_monthly_01',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_trial_01: 1 lesson used (student_2, 피아노 체험 완료)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_trial_01',
        subscriptionId: 'sub_trial_01',
        usedAt: now.subtract(const Duration(days: 2)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '체험 레슨',
        createdAt: now.subtract(const Duration(days: 2)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_package_03: 7 lessons used (student_3, 바이올린 만료 임박)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_p03_1',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 49)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 49)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_2',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 42)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_3',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 35)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_4',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 28)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_5',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '5회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_6',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '6회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_p03_7',
        subscriptionId: 'sub_package_03',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '김선생',
        instrument: '바이올린',
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
