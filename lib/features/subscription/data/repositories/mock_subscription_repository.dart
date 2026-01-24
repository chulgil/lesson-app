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
      // === Student 1 (김서연) - 활성 수강권들 ===

      // 1. 회차권 8회 - 이용중 (3/8회 사용, 5회 남음)
      Subscription(
        id: 'sub_001',
        studentId: 'student_1',
        membershipId: 'cm_001', // 행복음악학원 바이올린
        paymentId: 'pay_001',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 3,
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now.add(const Duration(days: 41)), // ~2 months validity
        amount: 380000,
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      // 표시: "5/8회 남음 (D-41)"

      // 2. 월정액 (4회) - 이용중 (2/4회 사용, 2회 남음)
      Subscription(
        id: 'sub_002',
        studentId: 'student_1',
        membershipId: 'cm_005', // 개인레슨 피아노
        paymentId: 'pay_002',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 2,
        startDate: monthStart,
        endDate: monthEnd,
        amount: 200000,
        status: SubscriptionStatus.active,
        createdAt: monthStart,
      ),
      // 표시: "2/4회 남음 (D-6)"

      // === Student 2 (이도현) - 만료 임박 + 만료됨 ===

      // 3. 회차권 8회 - 만료 임박 (6/8회 사용, 2회 남음)
      Subscription(
        id: 'sub_003',
        studentId: 'student_2',
        membershipId: 'cm_002', // 행복음악학원 피아노
        paymentId: 'pay_003',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 6,
        startDate: now.subtract(const Duration(days: 45)),
        endDate: now.add(const Duration(days: 15)),
        amount: 380000,
        status: SubscriptionStatus.expiringSoon,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      // 표시: "2/8회 남음 (D-15)" ⚠️

      // 4. 회차권 4회 - 소진됨 (만료)
      Subscription(
        id: 'sub_006',
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
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      // 표시: "0/4회 남음 (소진됨)"

      // === Student 3 (박지민) - 월정액 만료 임박 ===

      // 5. 월정액 (4회) - 만료 임박 (3/4회 사용, 1회 남음, D-3)
      Subscription(
        id: 'sub_004',
        studentId: 'student_3',
        membershipId: 'cm_003', // 개인레슨 바이올린
        paymentId: 'pay_004',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 3,
        startDate: monthStart,
        endDate: now.add(const Duration(days: 3)),
        amount: 250000,
        status: SubscriptionStatus.expiringSoon,
        createdAt: monthStart,
      ),
      // 표시: "1/4회 남음 (D-3)" ⚠️

      // 6. 지난달 월정액 - 만료됨
      Subscription(
        id: 'sub_007',
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
        createdAt: DateTime(now.year, now.month - 1, 1),
      ),
      // 표시: "0/4회 남음 (만료됨)"

      // === Student 4 (최예은) - 체험 + 일시정지 ===

      // 7. 체험 레슨
      Subscription(
        id: 'sub_005',
        studentId: 'student_4',
        membershipId: 'cm_004', // 개인레슨 첼로 체험
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        amount: 50000,
        status: SubscriptionStatus.active,
        createdAt: now,
      ),
      // 표시: "체험중"

      // 8. 회차권 8회 - 일시정지
      Subscription(
        id: 'sub_008',
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
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // 표시: "6/8회 남음 (일시정지)"
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
      // Package: check total lessons
      final remaining = subscription.totalLessons! - newUsedLessons;
      if (remaining <= 0) {
        newStatus = SubscriptionStatus.expired;
      } else if (remaining <= 2) {
        newStatus = SubscriptionStatus.expiringSoon;
      }
    } else if (subscription.type == SubscriptionType.monthly &&
        subscription.lessonsPerMonth != null) {
      // Monthly: check lessons per month
      final remaining = subscription.lessonsPerMonth! - newUsedLessons;
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
      if (s.type == SubscriptionType.package &&
          s.totalLessons != null &&
          (s.totalLessons! - s.usedLessons) <= 2) {
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
      'cm_005'
    ];
    return _subscriptions
        .where((s) => teacherMembershipIds.contains(s.membershipId))
        .toList();
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
