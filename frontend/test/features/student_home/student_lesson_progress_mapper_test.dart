import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_lesson_progress_item.dart';
import 'package:lessonaza/features/student_home/presentation/mappers/student_lesson_progress_mapper.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

void main() {
  test('maps teacher schedule proposal to action required progress item', () {
    final items = buildStudentLessonProgressItems(
      studentId: 'student_1',
      requests: const [],
      proposals: const [],
      subscriptions: [
        Subscription(
          id: 'sub_1',
          studentId: 'student_1',
          membershipId: 'membership_1',
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          amount: 280000,
          status: SubscriptionStatus.active,
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
      scheduleChangeEvents: [
        RequestEvent(
          id: 'schedule_change_1',
          requestId: '',
          actorType: ProposerRole.teacher,
          actorId: 'teacher_1',
          eventType: RequestEventType.scheduleChangeProposed,
          message: '아래 시간 중 선택해주세요',
          createdAt: DateTime(2026, 5, 4, 11),
          subscriptionId: 'sub_1',
          sessionNumber: 5,
        ),
      ],
    );

    expect(items, hasLength(1));
    expect(items.first.kind, StudentLessonProgressKind.scheduleChange);
    expect(items.first.priority, StudentLessonProgressPriority.actionRequired);
    expect(items.first.title, '선생님이 변경 시간을 제안했어요');
  });

  test('maps schedule change progress item route with target session', () {
    final items = buildStudentLessonProgressItems(
      studentId: 'student_1',
      requests: const [],
      proposals: const [],
      subscriptions: [
        Subscription(
          id: 'sub_1',
          studentId: 'student_1',
          membershipId: 'membership_1',
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          usedLessons: 2,
          amount: 280000,
          status: SubscriptionStatus.active,
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
      scheduleChangeEvents: [
        RequestEvent(
          id: 'schedule_change_2',
          requestId: '',
          actorType: ProposerRole.student,
          actorId: 'student_1',
          eventType: RequestEventType.scheduleChanged,
          message: '학교 시간표가 바뀌어서 전체 변경 부탁드립니다',
          createdAt: DateTime(2026, 5, 4, 10),
          subscriptionId: 'sub_1',
          sessionNumber: 4,
        ),
      ],
    );

    expect(items, hasLength(1));
    expect(items.first.route, '/subscriptions/sub_1?session=4');
    expect(items.first.routeExtra, {'viewerRole': 'student'});
  });

  test('routes to the linked request thread when lessonRequestIdBySubscription '
      'resolves the subscription (Option A reverse lookup)', () {
    final items = buildStudentLessonProgressItems(
      studentId: 'student_1',
      requests: const [],
      proposals: const [],
      subscriptions: [
        Subscription(
          id: 'sub_1',
          studentId: 'student_1',
          membershipId: 'membership_1',
          type: SubscriptionType.monthly,
          lessonsPerMonth: 4,
          usedLessons: 2,
          amount: 280000,
          status: SubscriptionStatus.active,
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
      scheduleChangeEvents: [
        RequestEvent(
          id: 'schedule_change_3',
          requestId: '',
          actorType: ProposerRole.student,
          actorId: 'student_1',
          eventType: RequestEventType.scheduleChanged,
          message: '학교 시간표가 바뀌어서 전체 변경 부탁드립니다',
          createdAt: DateTime(2026, 5, 4, 10),
          subscriptionId: 'sub_1',
          sessionNumber: 4,
        ),
      ],
      lessonRequestIdBySubscription: const {'sub_1': 'ulr_99'},
    );

    expect(items, hasLength(1));
    expect(items.first.route, '/schedule/request/ulr_99');
    expect(items.first.routeExtra, {'viewerRole': 'student'});
  });

  test('maps lesson request detail route with student viewer role', () {
    final items = buildStudentLessonProgressItems(
      studentId: 'student_1',
      requests: [
        UnifiedLessonRequest(
          id: 'request_1',
          type: LessonRequestType.regular,
          status: UnifiedRequestStatus.pending,
          studentId: 'student_1',
          teacherId: 'teacher_1',
          instrument: '바이올린',
          goal: UnifiedLessonGoal.hobby,
          experience: UnifiedExperienceLevel.beginner,
          createdAt: DateTime(2026, 5, 5, 9),
          preferredSlots: const [],
        ),
      ],
      proposals: const [],
      subscriptions: const [],
    );

    expect(items, hasLength(1));
    expect(items.first.route, '/schedule/request/request_1');
    expect(items.first.routeExtra, {'viewerRole': 'student'});
  });

  test(
    'maps lesson cancellation progress item with target session in title',
    () {
      final items = buildStudentLessonProgressItems(
        studentId: 'student_1',
        requests: const [],
        proposals: const [],
        subscriptions: [
          Subscription(
            id: 'sub_1',
            studentId: 'student_1',
            membershipId: 'membership_1',
            type: SubscriptionType.monthly,
            lessonsPerMonth: 4,
            usedLessons: 2,
            amount: 280000,
            status: SubscriptionStatus.active,
            createdAt: DateTime(2026, 4, 1),
          ),
        ],
        scheduleChangeEvents: [
          RequestEvent(
            id: 'schedule_cancel_1',
            requestId: '',
            actorType: ProposerRole.student,
            actorId: 'student_1',
            eventType: RequestEventType.lessonCancelled,
            message: '컨디션이 좋지 않아 취소 요청드립니다',
            createdAt: DateTime(2026, 5, 4, 10),
            subscriptionId: 'sub_1',
            sessionNumber: 3,
          ),
        ],
      );

      expect(items, hasLength(1));
      expect(items.first.title, '3회차 레슨 취소를 요청했어요');
      expect(items.first.subtitle, '변경/취소권 1회 사용 예정 · 다음 진행 레슨은 3회차');
    },
  );
}
