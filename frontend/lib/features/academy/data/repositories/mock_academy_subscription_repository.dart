import '../../domain/entities/academy_subscription.dart';
import '../../domain/entities/academy_enums.dart';
import '../../domain/repositories/academy_subscription_repository.dart';

/// Mock implementation of AcademySubscriptionRepository
class MockAcademySubscriptionRepository
    implements AcademySubscriptionRepository {
  late final Map<String, AcademySubscription> _subscriptions;
  late final Map<String, List<String>> _subscriptionsByStudent;

  MockAcademySubscriptionRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Create 8 mock subscriptions (academy: 6, teacher: 2)
    _subscriptions = {
      'sub_1': AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        studentId: 'student_1',
        teacherMemberId: 'member_2',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        studentCompensationExtraMinutesEnabled: true,
        includeExtraMinutesTextOnLateCancel: true,
        notifyOwnerOnLateCancel: true,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      'sub_2': AcademySubscription(
        id: 'sub_2',
        academyId: 'acad_1',
        studentId: 'student_2',
        teacherMemberId: 'member_2',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 24,
        studentCompensationExtraMinutesEnabled: true,
        includeExtraMinutesTextOnLateCancel: false,
        studentCompensationExtraMinutesMessage: '수강권 변경 요청하세요.',
        notifyOwnerOnLateCancel: false,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      'sub_3': AcademySubscription(
        id: 'sub_3',
        academyId: 'acad_2',
        studentId: 'student_5',
        teacherMemberId: 'member_4',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      'sub_4': AcademySubscription(
        id: 'sub_4',
        academyId: 'acad_2',
        studentId: 'student_6',
        teacherMemberId: 'member_4',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      'sub_5': AcademySubscription(
        id: 'sub_5',
        academyId: 'acad_3',
        studentId: 'student_9',
        teacherMemberId: 'member_6',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        createdAt: now.subtract(const Duration(days: 70)),
      ),
      'sub_6': AcademySubscription(
        id: 'sub_6',
        academyId: 'acad_3',
        studentId: 'student_10',
        teacherMemberId: 'member_6',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      'sub_7': AcademySubscription(
        id: 'sub_7',
        academyId: 'acad_1',
        studentId: 'student_1',
        teacherMemberId: 'member_2',
        ownership: SubscriptionOwnership.teacher,
        cancellationDeadlineHours: 6,
        notifyOwnerOnLateCancel: false,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      'sub_8': AcademySubscription(
        id: 'sub_8',
        academyId: 'acad_2',
        studentId: 'student_6',
        teacherMemberId: 'member_4',
        ownership: SubscriptionOwnership.teacher,
        cancellationDeadlineHours: 6,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    };

    // Build reverse map: student ID -> subscription IDs
    _subscriptionsByStudent = {};
    _subscriptions.forEach((subId, subscription) {
      if (!_subscriptionsByStudent.containsKey(subscription.studentId)) {
        _subscriptionsByStudent[subscription.studentId] = [];
      }
      _subscriptionsByStudent[subscription.studentId]!.add(subId);
    });
  }

  @override
  Future<List<AcademySubscription>> listByStudent(String studentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final subIds = _subscriptionsByStudent[studentId] ?? [];
    return subIds.map((id) => _subscriptions[id]!).toList();
  }

  @override
  Future<AcademySubscription?> getById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _subscriptions[id];
  }
}
