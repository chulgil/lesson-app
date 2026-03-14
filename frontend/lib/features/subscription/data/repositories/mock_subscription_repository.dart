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
      // Active Package Subscriptions
      // ═══════════════════════════════════════════════════════════════════

      // sub_pkg_01: student_1 (김민준, active 장기) - 바이올린 8회 패키지, 5/8 사용
      Subscription(
        id: 'sub_pkg_01',
        studentId: 'student_1',
        membershipId: 'membership_1',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 5,
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.add(const Duration(days: 25)),
        amount: 480000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 35)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 36)),
        paymentConfirmedAt: now.subtract(const Duration(days: 35)),
      ),

      // sub_pkg_02: student_3 (박지호, active 고급) - 첼로 12회 패키지, 2/12 사용 (시작 직후)
      Subscription(
        id: 'sub_pkg_02',
        studentId: 'student_3',
        membershipId: 'membership_3',
        type: SubscriptionType.package,
        totalLessons: 12,
        usedLessons: 2,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 80)),
        amount: 720000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 10)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.card,
        paidAt: now.subtract(const Duration(days: 11)),
        paymentConfirmedAt: now.subtract(const Duration(days: 10)),
      ),

      // sub_pkg_03: student_5 (정다은, active 초등) - 바이올린 4회 패키지, 3/4 사용 (1회 남음, expiringSoon)
      Subscription(
        id: 'sub_pkg_03',
        studentId: 'student_5',
        membershipId: 'membership_5',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 3,
        startDate: now.subtract(const Duration(days: 25)),
        endDate: now.add(const Duration(days: 5)),
        amount: 240000,
        status: SubscriptionStatus.expiringSoon,
        billingType: BillingType.perPackage,
        fifthWeekPolicy: FifthWeekPolicy.skip,
        createdAt: now.subtract(const Duration(days: 25)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.cash,
        paidAt: now.subtract(const Duration(days: 25)),
        paymentConfirmedAt: now.subtract(const Duration(days: 25)),
      ),

      // sub_pkg_04: student_12 (박준혁, active 미수금) - 바이올린 8회 패키지, 1/8 사용, paymentConfirmed=false
      Subscription(
        id: 'sub_pkg_04',
        studentId: 'student_12',
        membershipId: 'membership_12',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 53)),
        amount: 480000,
        status: SubscriptionStatus.active,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 7)),
        paymentConfirmed: false, // 미수금!
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Active Monthly Subscriptions
      // 월정액 가격 기준: 악기/레벨별 차등 (바이올린 320k, 피아노 280k, 피아노 보조 200k)
      // ═══════════════════════════════════════════════════════════════════

      // sub_mon_01: student_2 (이서연, active 신규) - 피아노 월 4회, 2/4 사용
      Subscription(
        id: 'sub_mon_01',
        studentId: 'student_2',
        membershipId: 'membership_2',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 2,
        startDate: monthStart,
        endDate: monthEnd,
        amount: 280000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 1,
        fifthWeekPolicy: FifthWeekPolicy.skip,
        createdAt: monthStart,
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: monthStart,
        paymentConfirmedAt: monthStart,
      ),

      // sub_mon_02: student_11 (이하은, active 복수악기 1) - 바이올린 월 4회, 1/4 사용
      Subscription(
        id: 'sub_mon_02',
        studentId: 'student_11',
        membershipId: 'membership_11',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 1,
        startDate: monthStart,
        endDate: monthEnd,
        amount: 320000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 5,
        fifthWeekPolicy: FifthWeekPolicy.bonus,
        createdAt: monthStart,
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.card,
        paidAt: monthStart,
        paymentConfirmedAt: monthStart,
      ),

      // sub_mon_03: student_11 (이하은, active 복수악기 2) - 피아노 월 2회, 0/2 사용
      Subscription(
        id: 'sub_mon_03',
        studentId: 'student_11',
        membershipId: 'membership_11',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 2,
        usedLessons: 0,
        startDate: monthStart,
        endDate: monthEnd,
        amount: 200000,
        status: SubscriptionStatus.active,
        billingType: BillingType.monthly,
        billingDay: 5,
        fifthWeekPolicy: FifthWeekPolicy.optional,
        createdAt: monthStart,
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.card,
        paidAt: monthStart,
        paymentConfirmedAt: monthStart,
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Trial Subscriptions
      // ═══════════════════════════════════════════════════════════════════

      // sub_trial_01: student_4 (최유진, trial) - 플루트 체험 1회, 0/1 미사용 (예정)
      Subscription(
        id: 'sub_trial_01',
        studentId: 'student_4',
        membershipId: 'membership_4',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        amount: 0,
        status: SubscriptionStatus.active,
        createdAt: now,
      ),

      // sub_trial_02: student_4 (최유진, trial) - 플루트 체험 1회, 1/1 사용 (이전 체험, 만료)
      Subscription(
        id: 'sub_trial_02',
        studentId: 'student_4',
        membershipId: 'membership_4',
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 14)),
        endDate: now.subtract(const Duration(days: 7)),
        amount: 30000,
        status: SubscriptionStatus.expired,
        createdAt: now.subtract(const Duration(days: 14)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.cash,
        paidAt: now.subtract(const Duration(days: 14)),
        paymentConfirmedAt: now.subtract(const Duration(days: 14)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Paused Subscriptions
      // ═══════════════════════════════════════════════════════════════════

      // sub_paused_01: student_6 (한서준, paused) - 피아노 8회 패키지, 3/8 사용 (시험 기간)
      Subscription(
        id: 'sub_paused_01',
        studentId: 'student_6',
        membershipId: 'membership_6',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 3,
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.add(const Duration(days: 30)),
        amount: 400000,
        status: SubscriptionStatus.paused,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 40)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 41)),
        paymentConfirmedAt: now.subtract(const Duration(days: 40)),
      ),

      // sub_paused_02: student_7 (강하윤, paused 장기) - 바이올린 4회 패키지, 1/4 사용 (건강 이유)
      Subscription(
        id: 'sub_paused_02',
        studentId: 'student_7',
        membershipId: 'membership_7',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 1,
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.add(const Duration(days: 40)),
        amount: 240000,
        status: SubscriptionStatus.paused,
        billingType: BillingType.perPackage,
        fifthWeekPolicy: FifthWeekPolicy.deduct,
        createdAt: now.subtract(const Duration(days: 20)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.cash,
        paidAt: now.subtract(const Duration(days: 20)),
        paymentConfirmedAt: now.subtract(const Duration(days: 20)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Expired Subscriptions
      // ═══════════════════════════════════════════════════════════════════

      // sub_exp_01: student_8 (김소연, inactive 졸업) - 바이올린 12회 패키지, 12/12 완전 사용
      Subscription(
        id: 'sub_exp_01',
        studentId: 'student_8',
        membershipId: 'membership_8',
        type: SubscriptionType.package,
        totalLessons: 12,
        usedLessons: 12,
        startDate: now.subtract(const Duration(days: 120)),
        endDate: now.subtract(const Duration(days: 30)),
        amount: 660000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 120)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 121)),
        paymentConfirmedAt: now.subtract(const Duration(days: 120)),
      ),

      // sub_exp_02: student_9 (한지민, inactive 만료) - 피아노 8회 패키지, 5/8 사용 (만료, 미갱신)
      Subscription(
        id: 'sub_exp_02',
        studentId: 'student_9',
        membershipId: 'membership_9',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 5,
        startDate: now.subtract(const Duration(days: 75)),
        endDate: now.subtract(const Duration(days: 15)),
        amount: 400000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 75)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.card,
        paidAt: now.subtract(const Duration(days: 76)),
        paymentConfirmedAt: now.subtract(const Duration(days: 75)),
      ),

      // sub_exp_03: student_1 (김민준) - 바이올린 8회 패키지, 8/8 사용 (이전 수강권, 히스토리)
      Subscription(
        id: 'sub_exp_03',
        studentId: 'student_1',
        membershipId: 'membership_1',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 8,
        startDate: now.subtract(const Duration(days: 100)),
        endDate: now.subtract(const Duration(days: 36)),
        amount: 480000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 100)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 101)),
        paymentConfirmedAt: now.subtract(const Duration(days: 100)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Edge Cases
      // ═══════════════════════════════════════════════════════════════════

      // sub_bonus_01: student_1 (김민준) - 바이올린 4회+보너스1, expired, 5/5 (bonusCount=1)
      Subscription(
        id: 'sub_bonus_01',
        studentId: 'student_1',
        membershipId: 'membership_1',
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 5,
        startDate: now.subtract(const Duration(days: 150)),
        endDate: now.subtract(const Duration(days: 101)),
        amount: 240000,
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        bonusCount: 1,
        bonusReason: '콩쿠르 준비',
        createdAt: now.subtract(const Duration(days: 150)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.cash,
        paidAt: now.subtract(const Duration(days: 150)),
        paymentConfirmedAt: now.subtract(const Duration(days: 150)),
      ),

      // sub_discount_01: student_3 (박지호) - 첼로 8회, active (discountAmount=50000, 형제 할인)
      Subscription(
        id: 'sub_discount_01',
        studentId: 'student_3',
        membershipId: 'membership_3',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 8,
        startDate: now.subtract(const Duration(days: 80)),
        endDate: now.subtract(const Duration(days: 11)),
        amount: 430000,
        originalAmount: 480000,
        discountAmount: 50000,
        discountReason: '형제 할인',
        status: SubscriptionStatus.expired,
        billingType: BillingType.perPackage,
        createdAt: now.subtract(const Duration(days: 80)),
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now.subtract(const Duration(days: 81)),
        paymentConfirmedAt: now.subtract(const Duration(days: 80)),
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
  Future<List<Subscription>> getExpired() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return _subscriptions.where((s) {
      if (s.status != SubscriptionStatus.expired) return false;
      // Only include recently expired (within 14 days)
      if (s.endDate != null && now.difference(s.endDate!).inDays > 14) {
        return false;
      }
      // Only include subscriptions with unused lessons remaining
      final remaining = s.remainingLessons;
      if (remaining != null && remaining <= 0) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) async {
    // In real implementation, this would join with memberships and classes
    // For mock, we return subscriptions for known memberships
    await Future.delayed(const Duration(milliseconds: 100));
    // For teacher_1, return all subscriptions with memberships in their classes
    final teacherMembershipIds = ['membership_1'];
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
      // sub_pkg_01: 5 lessons used (student_1, 김민준 바이올린 8회)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_pkg01_1',
        subscriptionId: 'sub_pkg_01',
        usedAt: now.subtract(const Duration(days: 32)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 32)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg01_2',
        subscriptionId: 'sub_pkg_01',
        usedAt: now.subtract(const Duration(days: 25)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg01_3',
        subscriptionId: 'sub_pkg_01',
        usedAt: now.subtract(const Duration(days: 18)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg01_4',
        subscriptionId: 'sub_pkg_01',
        usedAt: now.subtract(const Duration(days: 11)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg01_5',
        subscriptionId: 'sub_pkg_01',
        usedAt: now.subtract(const Duration(days: 4)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '5회차 레슨',
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_pkg_02: 2 lessons used (student_3, 박지호 첼로 12회 시작 직후)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_pkg02_1',
        subscriptionId: 'sub_pkg_02',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg02_2',
        subscriptionId: 'sub_pkg_02',
        usedAt: now.subtract(const Duration(days: 3)),
        teacherName: '박선생',
        instrument: '첼로',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_pkg_03: 3 lessons used (student_5, 정다은 바이올린 4회 1회 남음)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_pkg03_1',
        subscriptionId: 'sub_pkg_03',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg03_2',
        subscriptionId: 'sub_pkg_03',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_pkg03_3',
        subscriptionId: 'sub_pkg_03',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_pkg_04: 1 lesson used (student_12, 박준혁 바이올린 8회 미수금)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_pkg04_1',
        subscriptionId: 'sub_pkg_04',
        usedAt: now.subtract(const Duration(days: 4)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_mon_01: 2 lessons used (student_2, 이서연 피아노 월 4회)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_mon01_1',
        subscriptionId: 'sub_mon_01',
        usedAt: now.subtract(const Duration(days: 14)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      SubscriptionUsage(
        id: 'usage_mon01_2',
        subscriptionId: 'sub_mon_01',
        usedAt: now.subtract(const Duration(days: 7)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_mon_02: 1 lesson used (student_11, 이하은 바이올린 월 4회)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_mon02_1',
        subscriptionId: 'sub_mon_02',
        usedAt: now.subtract(const Duration(days: 10)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 10)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_trial_02: 1 lesson used (student_4, 최유진 플루트 이전 체험 만료)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_trial02_1',
        subscriptionId: 'sub_trial_02',
        usedAt: now.subtract(const Duration(days: 10)),
        teacherName: '최선생',
        instrument: '플루트',
        note: '체험 레슨',
        createdAt: now.subtract(const Duration(days: 10)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_paused_01: 3 lessons used (student_6, 한서준 피아노 8회 paused)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_paused01_1',
        subscriptionId: 'sub_paused_01',
        usedAt: now.subtract(const Duration(days: 35)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      SubscriptionUsage(
        id: 'usage_paused01_2',
        subscriptionId: 'sub_paused_01',
        usedAt: now.subtract(const Duration(days: 28)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      SubscriptionUsage(
        id: 'usage_paused01_3',
        subscriptionId: 'sub_paused_01',
        usedAt: now.subtract(const Duration(days: 21)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 21)),
        usageType: UsageType.lateCancellation,
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_paused_02: 1 lesson used (student_7, 강하윤 바이올린 4회 paused)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_paused02_1',
        subscriptionId: 'sub_paused_02',
        usedAt: now.subtract(const Duration(days: 17)),
        teacherName: '김선생',
        instrument: '바이올린',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 17)),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // sub_exp_02: 5 lessons used (student_9, 한지민 피아노 8회 만료 미갱신)
      // ═══════════════════════════════════════════════════════════════════
      SubscriptionUsage(
        id: 'usage_exp02_1',
        subscriptionId: 'sub_exp_02',
        usedAt: now.subtract(const Duration(days: 70)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '1회차 레슨',
        createdAt: now.subtract(const Duration(days: 70)),
      ),
      SubscriptionUsage(
        id: 'usage_exp02_2',
        subscriptionId: 'sub_exp_02',
        usedAt: now.subtract(const Duration(days: 63)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '2회차 레슨',
        createdAt: now.subtract(const Duration(days: 63)),
      ),
      SubscriptionUsage(
        id: 'usage_exp02_3',
        subscriptionId: 'sub_exp_02',
        usedAt: now.subtract(const Duration(days: 56)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '3회차 레슨',
        createdAt: now.subtract(const Duration(days: 56)),
      ),
      SubscriptionUsage(
        id: 'usage_exp02_4',
        subscriptionId: 'sub_exp_02',
        usedAt: now.subtract(const Duration(days: 42)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '4회차 레슨',
        createdAt: now.subtract(const Duration(days: 42)),
        usageType: UsageType.studentAbsent,
      ),
      SubscriptionUsage(
        id: 'usage_exp02_5',
        subscriptionId: 'sub_exp_02',
        usedAt: now.subtract(const Duration(days: 35)),
        teacherName: '이선생',
        instrument: '피아노',
        note: '5회차 레슨',
        createdAt: now.subtract(const Duration(days: 35)),
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
