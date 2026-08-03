import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/students/domain/entities/bulk_cancel_result.dart';
import 'package:lessonaza/features/students/domain/services/bulk_teacher_action_service.dart';
import 'package:lessonaza/features/subscription/domain/entities/pending_payment.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_usage.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Fakes
// ═══════════════════════════════════════════════════════════════════════════

class _FakeLessonRepository implements LessonRepository {
  final Map<String, Lesson> _lessons;
  final List<String> cancelledIds = [];
  final List<Lesson> updatedLessons = [];

  _FakeLessonRepository(List<Lesson> seed)
    : _lessons = {for (final l in seed) l.id: l};

  @override
  Future<List<Lesson>> getLessons() async => _lessons.values.toList();

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) async =>
      _lessons.values.where((l) => l.studentId == studentId).toList();

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) async => _lessons.values
      .where(
        (l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day,
      )
      .toList();

  @override
  Future<List<Lesson>> getLessonsByDateRange(
    DateTime start,
    DateTime end,
  ) async => _lessons.values
      .where((l) => !l.date.isBefore(start) && !l.date.isAfter(end))
      .toList();

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) async =>
      _lessons.values.take(limit).toList();

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) async =>
      _lessons.values.take(limit).toList();

  @override
  Future<Lesson?> getLesson(String id) async => _lessons[id];

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    _lessons[lesson.id] = lesson;
    return lesson;
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    _lessons[lesson.id] = lesson;
    updatedLessons.add(lesson);
    return lesson;
  }

  @override
  Future<void> deleteLesson(String id) async => _lessons.remove(id);

  @override
  Future<void> archiveLesson(String id) async => _lessons.remove(id);

  @override
  Future<void> unarchiveLesson(String id) async {}

  @override
  Future<void> cancelLesson(String id) async {
    cancelledIds.add(id);
    final existing = _lessons[id];
    if (existing != null) {
      _lessons[id] = existing.copyWith(status: LessonStatus.cancelledByTeacher);
    }
  }
}

class _FakeUnifiedLessonRequestRepository
    implements UnifiedLessonRequestRepository {
  final List<RequestEvent> addedEvents = [];

  @override
  Future<RequestEvent> addEvent(RequestEvent event) async {
    addedEvents.add(event);
    return event;
  }

  @override
  Future<List<UnifiedLessonRequest>> getByStudentId(String studentId) async {
    return [
      UnifiedLessonRequest(
        id: 'R_$studentId',
        studentId: studentId,
        teacherId: 'T1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<List<RequestEvent>> getEventsByRequestId(String requestId) async => [];

  @override
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request) async =>
      request;

  @override
  Future<UnifiedLessonRequest?> getById(String id) async => null;

  @override
  Future<List<UnifiedLessonRequest>> getByTeacherId(String teacherId) async =>
      [];

  @override
  Future<List<UnifiedLessonRequest>> getPendingByTeacherId(
    String teacherId,
  ) async => [];

  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async =>
      request;

  @override
  Future<UnifiedLessonRequest> approve(String id) => throw UnimplementedError();

  @override
  Future<UnifiedLessonRequest> withdrawApproval(String id) =>
      throw UnimplementedError();

  @override
  Future<UnifiedLessonRequest> reject(String id, {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<UnifiedLessonRequest> proposeAlternatives(
    String id, {
    required List<TimeSlotOption> slots,
    String? message,
  }) => throw UnimplementedError();

  @override
  Future<UnifiedLessonRequest> acceptAlternative(
    String id, {
    required int selectedSlotIndex,
    String? message,
  }) => throw UnimplementedError();

  @override
  Future<UnifiedLessonRequest> counterPropose(
    String id, {
    required TimeSlotOption slot,
    String? message,
  }) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Subscription>> getByStudentId(String studentId) async {
    return [
      Subscription(
        id: 'SUB_$studentId',
        studentId: studentId,
        membershipId: 'M_$studentId',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 2,
        amount: 320000,
        status: SubscriptionStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) async =>
      null;

  @override
  Future<Subscription?> getById(String id) async => null;

  @override
  Future<Subscription> create(Subscription subscription) async => subscription;

  @override
  Future<Subscription> update(Subscription subscription) async => subscription;

  @override
  Future<Subscription> useLesson(
    String id, {
    String? lessonId,
    String? teacherName,
    String? instrument,
  }) => throw UnimplementedError();

  @override
  Future<Subscription> useReschedule(String id) => throw UnimplementedError();

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) async {}

  @override
  Future<List<Subscription>> getExpiringSoon() async => [];

  @override
  Future<List<Subscription>> getExpired() async => [];

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) async => [];

  @override
  Stream<List<Subscription>> watchByStudentId(String studentId) =>
      const Stream.empty();

  @override
  Stream<Subscription?> watchActiveByMembershipId(String membershipId) =>
      const Stream.empty();

  @override
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId) async =>
      [];

  @override
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  }) => throw UnimplementedError();

  @override
  Future<Subscription> undoConfirmPayment(String id) =>
      throw UnimplementedError();

  @override
  Future<List<PendingPayment>> getPendingPayments() async => [];

  @override
  Future<int> getPendingPaymentCount() async => 0;

  @override
  Future<void> resendProposalReminder(String proposalId) async {}

  @override
  Future<bool> requestPaymentConfirmation(String proposalId) async => true;

  @override
  Future<void> revokeProposal(String proposalId) async {}

  @override
  Future<List<SubscriptionUsage>> getUsageHistory(
    String subscriptionId,
  ) async => [];

  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) async => usage;
}

Lesson _lesson({
  required String id,
  required String studentId,
  required DateTime date,
  LessonStatus status = LessonStatus.scheduled,
}) {
  return Lesson(
    id: id,
    studentId: studentId,
    studentName: 'Student-$studentId',
    instrument: '바이올린',
    date: date,
    startTime: '14:00',
    status: status,
    // _FakeSubscriptionRepository 가 돌려주는 수강권 id 와 일치시켜야
    // _createCancelEvent 가 챗 이벤트를 만든다 (학생 통지의 실제 경로).
    subscriptionId: 'SUB_$studentId',
    createdAt: DateTime(2026, 1, 1),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('BulkTeacherActionService.cancelLessonsOnDate', () {
    test('대상 날짜에 레슨이 있는 학생만 취소 + 챗 이벤트 생성', () async {
      final targetDate = DateTime(2026, 5, 1);
      final lessonRepo = _FakeLessonRepository([
        _lesson(id: 'L1', studentId: 'S1', date: targetDate),
        _lesson(id: 'L2', studentId: 'S2', date: targetDate),
        _lesson(
          id: 'L3',
          studentId: 'S3',
          date: DateTime(2026, 5, 2), // 다른 날짜
        ),
      ]);
      final requestRepo = _FakeUnifiedLessonRequestRepository();

      final service = BulkTeacherActionService(
        lessonRepository: lessonRepo,
        requestRepository: requestRepo,
        subscriptionRepository: _FakeSubscriptionRepository(),
      );

      final result = await service.cancelLessonsOnDate(
        teacherId: 'T1',
        studentIds: const ['S1', 'S2', 'S3'],
        targetDate: targetDate,
        reason: '선생님 개인 사정',
      );

      expect(result.cancelledLessonCount, 2);
      expect(result.notifiedStudentCount, 2);
      expect(result.skippedStudentIds, ['S3']);
      expect(
        lessonRepo.updatedLessons.map((l) => l.id),
        containsAll(['L1', 'L2']),
      );
      // 차감 없음 + reschedule 가능 보장: cancelledByTeacher 로 명시 설정
      for (final l in lessonRepo.updatedLessons) {
        expect(l.status, LessonStatus.cancelledByTeacher);
        expect(l.status.isDeducted, isFalse);
        expect(l.status.allowsReschedule, isTrue);
      }
      // #1212 학생 통지는 수강권 챗 이벤트(BE)가 SSOT.
      // FE 로컬 알림은 액터(교사) 기기 전용이라 상대 통지로 쓰지 않는다.
      expect(requestRepo.addedEvents.map((e) => e.eventType).toSet(), {
        RequestEventType.lessonCancelledByTeacher,
      });
      expect(requestRepo.addedEvents.map((e) => e.requestId).toSet(), {
        'R_S1',
        'R_S2',
      });
      expect(requestRepo.addedEvents.map((e) => e.message).toSet(), {
        '선생님 개인 사정',
      });
    });

    test('대상 날짜에 취소된 레슨은 건드리지 않음', () async {
      final targetDate = DateTime(2026, 5, 1);
      final lessonRepo = _FakeLessonRepository([
        _lesson(
          id: 'L1',
          studentId: 'S1',
          date: targetDate,
          status: LessonStatus.cancelledByTeacher,
        ),
      ]);
      final service = BulkTeacherActionService(
        lessonRepository: lessonRepo,
        requestRepository: _FakeUnifiedLessonRequestRepository(),
        subscriptionRepository: _FakeSubscriptionRepository(),
      );

      final result = await service.cancelLessonsOnDate(
        teacherId: 'T1',
        studentIds: const ['S1'],
        targetDate: targetDate,
      );

      expect(result.cancelledLessonCount, 0);
      expect(result.skippedStudentIds, ['S1']);
      expect(lessonRepo.updatedLessons, isEmpty);
    });
  });

  group('BulkTeacherActionService.previewAffectedLessons', () {
    test('대상 날짜의 scheduled 레슨만 반환 (취소 상태 제외)', () async {
      final targetDate = DateTime(2026, 5, 1);
      final lessonRepo = _FakeLessonRepository([
        _lesson(id: 'L1', studentId: 'S1', date: targetDate),
        _lesson(
          id: 'L2',
          studentId: 'S2',
          date: targetDate,
          status: LessonStatus.cancelledByTeacher,
        ),
        _lesson(id: 'L3', studentId: 'S3', date: DateTime(2026, 5, 2)),
      ]);
      final service = BulkTeacherActionService(
        lessonRepository: lessonRepo,
        requestRepository: _FakeUnifiedLessonRequestRepository(),
        subscriptionRepository: _FakeSubscriptionRepository(),
      );

      final preview = await service.previewAffectedLessons(
        studentIds: const ['S1', 'S2', 'S3'],
        targetDate: targetDate,
      );

      expect(preview.map((l) => l.id), ['L1']);
    });
  });

  group('BulkTeacherActionService.broadcastMessage', () {
    test('선택된 모든 학생 챗에 teacherAnnouncement 이벤트 생성', () async {
      final requestRepo = _FakeUnifiedLessonRequestRepository();
      final service = BulkTeacherActionService(
        lessonRepository: _FakeLessonRepository(const []),
        requestRepository: requestRepo,
        subscriptionRepository: _FakeSubscriptionRepository(),
      );

      final count = await service.broadcastMessage(
        teacherId: 'T1',
        studentIds: const ['S1', 'S2', 'S3'],
        title: '5월 일정 안내',
        body: '이번 주 금요일부터 연휴입니다.',
      );

      expect(count, 3);
      // #1212 학생 통지는 수강권 챗 이벤트(BE)가 SSOT — FE 로컬 알림 없음.
      expect(requestRepo.addedEvents.map((e) => e.eventType).toSet(), {
        RequestEventType.teacherAnnouncement,
      });
      expect(requestRepo.addedEvents.map((e) => e.requestId).toSet(), {
        'R_S1',
        'R_S2',
        'R_S3',
      });
      for (final e in requestRepo.addedEvents) {
        expect(e.message, '5월 일정 안내\n이번 주 금요일부터 연휴입니다.');
      }
    });

    test('빈 학생 목록 → 아무 이벤트도 만들지 않고 0 반환', () async {
      final requestRepo = _FakeUnifiedLessonRequestRepository();
      final service = BulkTeacherActionService(
        lessonRepository: _FakeLessonRepository(const []),
        requestRepository: requestRepo,
        subscriptionRepository: _FakeSubscriptionRepository(),
      );

      final count = await service.broadcastMessage(
        teacherId: 'T1',
        studentIds: const [],
        title: 'title',
        body: 'body',
      );

      expect(count, 0);
      expect(requestRepo.addedEvents, isEmpty);
    });
  });

  group('BulkCancelResult', () {
    test('hasSkipped = skippedStudentIds.isNotEmpty', () {
      const a = BulkCancelResult(
        cancelledLessonCount: 2,
        notifiedStudentCount: 2,
        skippedStudentIds: ['S3'],
      );
      const b = BulkCancelResult(
        cancelledLessonCount: 2,
        notifiedStudentCount: 2,
        skippedStudentIds: [],
      );
      expect(a.hasSkipped, isTrue);
      expect(b.hasSkipped, isFalse);
    });
  });
}
