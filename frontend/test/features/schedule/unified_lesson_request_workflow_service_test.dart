import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/services/unified_lesson_request_workflow_service.dart';

void main() {
  group('UnifiedLessonRequestWorkflowService', () {
    test(
      'createRequest fills current user id and records initial event',
      () async {
        final repository = MockUnifiedLessonRequestRepository();
        final service = UnifiedLessonRequestWorkflowService(repository);
        final request = UnifiedLessonRequest(
          id: 'workflow-create-001',
          studentId: '',
          teacherId: 'teacher_1',
          type: LessonRequestType.regular,
          instrument: '피아노',
          goal: UnifiedLessonGoal.hobby,
          experience: UnifiedExperienceLevel.beginner,
          preferredSlots: [
            PreferredTimeSlot(
              priority: 1,
              dayOfWeek: 2,
              startTime: '15:00',
              endTime: '16:00',
            ),
          ],
          message: '화요일 오후를 원합니다',
          createdAt: DateTime(2026, 5, 3),
        );

        final result = await service.createRequest(
          request,
          currentUserId: 'student_context_001',
        );

        expect(result.studentId, 'student_context_001');
        final stored = await repository.getById(request.id);
        expect(stored!.studentId, 'student_context_001');
        final events = await repository.getEventsByRequestId(request.id);
        expect(events.single.actorType, ProposerRole.student);
        expect(events.single.actorId, 'student_context_001');
        expect(events.single.eventType, RequestEventType.initialRequest);
        expect(events.single.suggestedSlots.single.dayOfWeek, 2);
        expect(events.single.message, '화요일 오후를 원합니다');
      },
    );

    test('approveRequest confirms time and records selected slot', () async {
      final repository = MockUnifiedLessonRequestRepository();
      final service = UnifiedLessonRequestWorkflowService(repository);
      final request = UnifiedLessonRequest(
        id: 'workflow-approve-001',
        studentId: 'student_approve_001',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '피아노',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        preferredSlots: [
          PreferredTimeSlot(
            priority: 1,
            dayOfWeek: 2,
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
        status: UnifiedRequestStatus.pending,
        createdAt: DateTime(2026, 5, 3),
      );
      await repository.create(request);

      final result = await service.approveRequest(
        request.id,
        teacherId: request.teacherId,
        selectedSlotIndex: 0,
        message: '이 시간으로 진행합니다',
      );

      expect(result.status, UnifiedRequestStatus.timeConfirmed);
      expect(result.confirmedAt, isNotNull);
      final events = await repository.getEventsByRequestId(request.id);
      final event = events.lastWhere(
        (event) => event.eventType == RequestEventType.approve,
      );
      expect(event.actorType, ProposerRole.teacher);
      expect(event.actorId, request.teacherId);
      expect(event.selectedSlotIndex, 0);
      expect(event.message, '이 시간으로 진행합니다');
    });
  });
}
