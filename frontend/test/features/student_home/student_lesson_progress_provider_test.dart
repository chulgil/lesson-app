import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/schedule/domain/entities/schedule_confirmation_card.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_lesson_progress_item.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_lesson_progress_provider.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

void main() {
  const studentId = 'student_1';

  test(
    'subscription issued with schedule confirmation becomes action item',
    () async {
      final container = _container(
        scheduleCards: [
          ScheduleConfirmationCard(
            id: 'card_1',
            studentId: studentId,
            teacherId: 'teacher_1',
            teacherName: '김선생님',
            instrument: '바이올린',
            subscriptionId: 'sub_1',
            cardType: ScheduleCardType.reEnrollment,
            createdAt: DateTime(2026, 5, 4, 12),
            totalLessons: 8,
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(
        studentLessonProgressProvider(studentId).future,
      );

      expect(items, hasLength(1));
      expect(items.first.kind, StudentLessonProgressKind.scheduleConfirmation);
      expect(
        items.first.priority,
        StudentLessonProgressPriority.actionRequired,
      );
      expect(items.first.title, '수강권이 준비됐어요');
      expect(items.first.subtitle, '첫 레슨 시간을 확인해주세요');
      expect(items.first.statusLabel, '확인 필요');
    },
  );

  test('pending proposal becomes action item', () async {
    final container = _container(
      proposals: [
        SubscriptionProposal(
          id: 'proposal_1',
          teacherId: 'teacher_1',
          studentId: studentId,
          templateId: 'template_1',
          message: '이번 달 수강권 조건을 확인해주세요',
          createdAt: DateTime(2026, 5, 4, 11),
          expiresAt: DateTime(2026, 5, 11),
        ),
      ],
    );
    addTearDown(container.dispose);

    final items = await container.read(
      studentLessonProgressProvider(studentId).future,
    );

    expect(items, hasLength(1));
    expect(items.first.kind, StudentLessonProgressKind.proposal);
    expect(items.first.priority, StudentLessonProgressPriority.actionRequired);
    expect(items.first.title, '수강권 조건을 확인해주세요');
    expect(items.first.subtitle, '이번 달 수강권 조건을 확인해주세요');
  });

  test('empty sources produce empty progress list', () async {
    final container = _container();
    addTearDown(container.dispose);

    final items = await container.read(
      studentLessonProgressProvider(studentId).future,
    );

    expect(items, isEmpty);
  });
}

ProviderContainer _container({
  List<UnifiedLessonRequest> requests = const [],
  List<SubscriptionProposal> proposals = const [],
  SubscriptionProposal? renewalProposal,
  List<Subscription> subscriptions = const [],
  List<ScheduleConfirmationCard> scheduleCards = const [],
}) {
  const studentId = 'student_1';
  return ProviderContainer(
    overrides: [
      studentTodayRequestsProvider(
        studentId,
      ).overrideWith((ref) async => requests),
      pendingStudentProposalsProvider(
        studentId,
      ).overrideWith((ref) async => proposals),
      pendingRenewalProposalProvider(
        studentId,
      ).overrideWith((ref) async => renewalProposal),
      studentSubscriptionsProvider(
        studentId,
      ).overrideWith((ref) async => subscriptions),
      pendingScheduleConfirmationCardsProvider(
        studentId,
      ).overrideWith((ref) async => scheduleCards),
    ],
  );
}
