import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../relationship/relationship_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../settings/settings_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';
import 'lesson_policy_providers.dart';
import 'subscription_providers.dart';

part 'subscription_issue_flow_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Student>> subscriptionIssueStudents(
  SubscriptionIssueStudentsRef ref,
) async {
  return ref.watch(studentsProvider.future);
}

@Riverpod(keepAlive: true)
Future<Student?> subscriptionIssueStudent(
  SubscriptionIssueStudentRef ref,
  String studentId,
) async {
  return ref.watch(studentProvider(studentId).future);
}

@Riverpod(keepAlive: true)
Future<List<ClassMembership>> subscriptionIssueMemberships(
  SubscriptionIssueMembershipsRef ref,
  String studentId,
) async {
  return ref.watch(studentMembershipsProvider(studentId).future);
}

@Riverpod(keepAlive: true)
Future<LessonPolicy?> subscriptionIssueEffectivePolicy(
  SubscriptionIssueEffectivePolicyRef ref,
  ClassMembership membership,
) async {
  final lessonClass = await ref.watch(
    lessonClassProvider(membership.lessonClassId).future,
  );
  if (lessonClass == null) return null;

  return ref.watch(
    effectivePolicyProvider(
      teacherId: lessonClass.teacherId,
      lessonClassId: membership.lessonClassId,
    ).future,
  );
}

@Riverpod(keepAlive: true)
SubscriptionIssueFlowController subscriptionIssueFlowController(
  SubscriptionIssueFlowControllerRef ref,
) {
  return SubscriptionIssueFlowController(ref);
}

class SubscriptionIssueFlowController {
  final SubscriptionIssueFlowControllerRef _ref;

  SubscriptionIssueFlowController(this._ref);

  Future<String?> teacherIdForMembership({
    required String studentId,
    required String membershipId,
  }) async {
    final membership = await membershipForStudent(
      studentId: studentId,
      membershipId: membershipId,
    );
    if (membership == null) return null;

    final lessonClass = await _ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );
    return lessonClass?.teacherId;
  }

  Future<String> studentName(String studentId) async {
    final student = await _ref.read(
      subscriptionIssueStudentProvider(studentId).future,
    );
    return student?.name ?? '';
  }

  Future<ClassMembership?> membershipForStudent({
    required String studentId,
    required String membershipId,
  }) async {
    final memberships = await _ref.read(
      subscriptionIssueMembershipsProvider(studentId).future,
    );
    for (final membership in memberships) {
      if (membership.id == membershipId) return membership;
    }
    return null;
  }

  Future<void> updateMembershipLocationTravel({
    required String studentId,
    required String membershipId,
    String? locationId,
    required int travelTime,
  }) async {
    final membership = await membershipForStudent(
      studentId: studentId,
      membershipId: membershipId,
    );
    if (membership == null) return;

    final updated = membership.copyWith(
      lessonLocationId: locationId,
      travelTimeMinutes: travelTime,
    );
    await _ref.read(membershipRepositoryProvider).update(updated);
  }

  Future<void> activateRelationshipForSubscription({
    required String teacherId,
    required String studentId,
    required String subscriptionId,
  }) async {
    final relationRepo = _ref.read(teacherStudentRelationRepositoryProvider);
    await relationRepo.onSubscriptionIssued(
      teacherId: teacherId,
      studentId: studentId,
      subscriptionId: subscriptionId,
    );
  }

  Future<void> updateLessonRequestForIssuedSubscription({
    required String lessonRequestId,
    required String subscriptionId,
    required UnifiedRequestStatus status,
  }) async {
    final repo = _ref.read(unifiedLessonRequestRepositoryProvider);
    final request = await repo.getById(lessonRequestId);
    if (request == null) return;

    await repo.update(
      request.copyWith(proposalId: subscriptionId, status: status),
    );
  }

  Future<({String teacherId, String teacherName})?>
  lessonClassInfoForMembership(ClassMembership membership) async {
    final lessonClass = await _ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );
    if (lessonClass == null) return null;
    return (teacherId: lessonClass.teacherId, teacherName: lessonClass.name);
  }

  Future<List<Subscription>> studentSubscriptions(String studentId) {
    return _ref.read(studentSubscriptionsProvider(studentId).future);
  }

  Future<List<({int day, String time})>> alternativeSlots({
    required String teacherId,
    int? primaryDay,
    String? primaryTime,
  }) async {
    if (teacherId.isEmpty) return [];

    final settings = await _ref.read(
      teacherSettingsByIdProvider(teacherId).future,
    );
    final alternatives = <({int day, String time})>[];

    for (final slot in settings.availableSlots) {
      if (!slot.isActive) continue;

      final slotDay = slot.dayOfWeek;
      final slotTimeStr =
          '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';

      if (slotDay == primaryDay && slotTimeStr == primaryTime) continue;

      final isDuplicate = alternatives.any(
        (a) => a.day == slotDay && a.time == slotTimeStr,
      );
      if (isDuplicate) continue;

      alternatives.add((day: slotDay, time: slotTimeStr));
      if (alternatives.length >= 2) break;
    }

    return alternatives;
  }

  Future<void> createScheduleConfirmationCard({
    required String studentId,
    required String teacherId,
    required String teacherName,
    String? instrument,
    required String subscriptionId,
    required ScheduleCardType cardType,
    int? totalLessons,
    int? suggestedDay,
    String? suggestedTime,
    int? lessonDuration,
    int? suggestedDay2,
    String? suggestedTime2,
    int? suggestedDay3,
    String? suggestedTime3,
  }) async {
    await _ref
        .read(scheduleConfirmationCardNotifierProvider.notifier)
        .createCard(
          studentId: studentId,
          teacherId: teacherId,
          teacherName: teacherName,
          instrument: instrument,
          subscriptionId: subscriptionId,
          cardType: cardType,
          totalLessons: totalLessons,
          suggestedDay: suggestedDay,
          suggestedTime: suggestedTime,
          lessonDuration: lessonDuration,
          suggestedDay2: suggestedDay2,
          suggestedTime2: suggestedTime2,
          suggestedDay3: suggestedDay3,
          suggestedTime3: suggestedTime3,
        );
  }
}
