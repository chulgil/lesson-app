import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';

/// Mock implementation of UnifiedLessonRequestRepository for development.
/// v4.0: 10 boundary-value scenarios with RequestEvent history.
class MockUnifiedLessonRequestRepository
    implements UnifiedLessonRequestRepository {
  final Map<String, UnifiedLessonRequest> _requests = {};
  final Map<String, List<RequestEvent>> _events = {};

  MockUnifiedLessonRequestRepository() {
    _seedData();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RequestEvent access
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all events for a request, sorted by createdAt ascending.
  Future<List<RequestEvent>> getEventsByRequestId(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final events = _events[requestId] ?? [];
    return List.of(events)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Add a new event to a request's history.
  Future<RequestEvent> addEvent(RequestEvent event) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _events.putIfAbsent(event.requestId, () => []);
    _events[event.requestId]!.add(event);
    return event;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Seed data — 10 boundary-value scenarios
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the next occurrence of [targetWeekday] (1=Mon...7=Sun) from [from].
  DateTime _nextWeekday(DateTime from, int targetWeekday) {
    final daysAhead = (targetWeekday - from.weekday + 7) % 7;
    return DateTime(from.year, from.month, from.day + (daysAhead == 0 ? 7 : daysAhead));
  }

  void _seedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 대기 중 (희망시간 3개) — pending, 이벤트 1건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      message: '바이올린을 처음 배우고 싶습니다',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: _nextWeekday(today, 1),
          dayOfWeek: 1,
          startTime: '14:00',
          endTime: '15:00',
        ),
        PreferredTimeSlot(
          priority: 2,
          date: _nextWeekday(today, 3),
          dayOfWeek: 3,
          startTime: '10:00',
          endTime: '11:00',
        ),
        PreferredTimeSlot(
          priority: 3,
          date: _nextWeekday(today, 5),
          dayOfWeek: 5,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
    ));
    _addEvents('ulr_1', [
      RequestEvent(
        id: 'evt_1_1',
        requestId: 'ulr_1',
        actorType: ProposerRole.student,
        actorId: 'student_1',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_1_1', dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
          TimeSlotOption(id: 'ts_1_2', dayOfWeek: 3, startTime: '10:00', endTime: '11:00'),
          TimeSlotOption(id: 'ts_1_3', dayOfWeek: 5, startTime: '16:00', endTime: '17:00'),
        ],
        message: '바이올린을 처음 배우고 싶습니다',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 협상 중 라운드 3 — negotiating, 이벤트 6건 (3왕복)
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_2',
      studentId: 'student_2',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.exam,
      experience: UnifiedExperienceLevel.intermediate,
      message: '입시 준비 중입니다',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: _nextWeekday(today, 3),
          dayOfWeek: 3,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
      status: UnifiedRequestStatus.negotiating,
      currentRound: 3,
      createdAt: now.subtract(const Duration(days: 2)),
    ));
    _addEvents('ulr_2', [
      RequestEvent(
        id: 'evt_2_1',
        requestId: 'ulr_2',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_init_1', dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
        ],
        message: '입시 준비 중입니다',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      RequestEvent(
        id: 'evt_2_2',
        requestId: 'ulr_2',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_1', dayOfWeek: 1, startTime: '15:00', endTime: '16:00'),
          TimeSlotOption(id: 'ts_2_2', dayOfWeek: 4, startTime: '14:00', endTime: '15:00'),
        ],
        message: '목요일 4시는 어려워요. 다른 시간 확인해주세요!',
        createdAt: now.subtract(const Duration(days: 1, hours: 20)),
      ),
      RequestEvent(
        id: 'evt_2_3',
        requestId: 'ulr_2',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.counterPropose,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_3', dayOfWeek: 2, startTime: '17:00', endTime: '18:00'),
        ],
        message: '월요일은 학교가 있어서 화요일 저녁이 좋겠습니다',
        createdAt: now.subtract(const Duration(days: 1, hours: 16)),
      ),
      RequestEvent(
        id: 'evt_2_4',
        requestId: 'ulr_2',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_4', dayOfWeek: 2, startTime: '18:00', endTime: '19:00'),
          TimeSlotOption(id: 'ts_2_5', dayOfWeek: 4, startTime: '18:00', endTime: '19:00'),
        ],
        message: '화요일 5시는 레슨이 있어서 6시는 어떨까요?',
        createdAt: now.subtract(const Duration(days: 1, hours: 10)),
      ),
      RequestEvent(
        id: 'evt_2_5',
        requestId: 'ulr_2',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.counterPropose,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_6', dayOfWeek: 2, startTime: '18:30', endTime: '19:30'),
        ],
        message: '6시 반부터 가능합니다',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      RequestEvent(
        id: 'evt_2_6',
        requestId: 'ulr_2',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_2_7', dayOfWeek: 2, startTime: '18:30', endTime: '19:30'),
          TimeSlotOption(id: 'ts_2_8', dayOfWeek: 4, startTime: '18:30', endTime: '19:30'),
        ],
        message: '화요일이나 목요일 6시 반 중 선택해주세요',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 오늘 완료 — completed, 이벤트 4건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_3',
      studentId: 'student_3',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '첼로',
      goal: UnifiedLessonGoal.major,
      experience: UnifiedExperienceLevel.advanced,
      preferredDuration: 60,
      status: UnifiedRequestStatus.completed,
      currentRound: 1,
      confirmedAt: today.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(days: 3)),
    ));
    _addEvents('ulr_3', [
      RequestEvent(
        id: 'evt_3_1',
        requestId: 'ulr_3',
        actorType: ProposerRole.student,
        actorId: 'student_3',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_3_1', dayOfWeek: 0, startTime: '10:00', endTime: '11:00'),
          TimeSlotOption(id: 'ts_3_2', dayOfWeek: 4, startTime: '18:00', endTime: '19:00'),
        ],
        message: '전공 레슨 부탁드립니다',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      RequestEvent(
        id: 'evt_3_2',
        requestId: 'ulr_3',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.approve,
        selectedSlotIndex: 0,
        createdAt: now.subtract(const Duration(days: 2, hours: 20)),
      ),
      RequestEvent(
        id: 'evt_3_3',
        requestId: 'ulr_3',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposalSent,
        message: '수강권을 보내드렸습니다',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      RequestEvent(
        id: 'evt_3_4',
        requestId: 'ulr_3',
        actorType: ProposerRole.student,
        actorId: 'student_3',
        eventType: RequestEventType.completed,
        createdAt: today.subtract(const Duration(hours: 3)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 4. 과거 완료 (어제) — completed, trial, 이벤트 3건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_4',
      studentId: 'student_4',
      teacherId: 'teacher_1',
      type: LessonRequestType.trial,
      instrument: '비올라',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      preferredDuration: 30,
      status: UnifiedRequestStatus.completed,
      confirmedAt: today.subtract(const Duration(days: 1, hours: 5)),
      createdAt: now.subtract(const Duration(days: 5)),
    ));
    _addEvents('ulr_4', [
      RequestEvent(
        id: 'evt_4_1',
        requestId: 'ulr_4',
        actorType: ProposerRole.student,
        actorId: 'student_4',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_4_1', dayOfWeek: 5, startTime: '14:00', endTime: '14:30'),
        ],
        message: '체험레슨 신청합니다',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      RequestEvent(
        id: 'evt_4_2',
        requestId: 'ulr_4',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.approve,
        selectedSlotIndex: 0,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      RequestEvent(
        id: 'evt_4_3',
        requestId: 'ulr_4',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.completed,
        createdAt: today.subtract(const Duration(days: 1, hours: 5)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 5. 학생 취소 — cancelled, 이벤트 2건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_5',
      studentId: 'student_5',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '플루트',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      preferredDuration: 60,
      status: UnifiedRequestStatus.cancelled,
      cancelledAt: today.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(days: 1)),
    ));
    _addEvents('ulr_5', [
      RequestEvent(
        id: 'evt_5_1',
        requestId: 'ulr_5',
        actorType: ProposerRole.student,
        actorId: 'student_5',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_5_1', dayOfWeek: 1, startTime: '11:00', endTime: '12:00'),
        ],
        message: '플루트 배우고 싶어요',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      RequestEvent(
        id: 'evt_5_2',
        requestId: 'ulr_5',
        actorType: ProposerRole.student,
        actorId: 'student_5',
        eventType: RequestEventType.cancel,
        message: '일정이 변경되어 취소합니다',
        createdAt: today.subtract(const Duration(hours: 2)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 6. 기간 만료 — expired, 이벤트 1건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_6',
      studentId: 'student_6',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '클라리넷',
      goal: UnifiedLessonGoal.other,
      experience: UnifiedExperienceLevel.beginner,
      preferredDuration: 60,
      status: UnifiedRequestStatus.expired,
      createdAt: now.subtract(const Duration(days: 8)),
    ));
    _addEvents('ulr_6', [
      RequestEvent(
        id: 'evt_6_1',
        requestId: 'ulr_6',
        actorType: ProposerRole.student,
        actorId: 'student_6',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_6_1', dayOfWeek: 3, startTime: '15:00', endTime: '16:00'),
        ],
        message: '클라리넷을 배우고 싶습니다',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      RequestEvent(
        id: 'evt_6_2',
        requestId: 'ulr_6',
        actorType: ProposerRole.student,
        actorId: 'student_6',
        eventType: RequestEventType.expire,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 7. 학원 요청 - 바이올린 — pending, 이벤트 1건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_7',
      studentId: 'student_3',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.intermediate,
      academyId: 'academy_2',
      message: '학원 바이올린 레슨 요청',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: _nextWeekday(today, 2),
          dayOfWeek: 2,
          startTime: '14:00',
          endTime: '15:00',
        ),
      ],
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 1)),
    ));
    _addEvents('ulr_7', [
      RequestEvent(
        id: 'evt_7_1',
        requestId: 'ulr_7',
        actorType: ProposerRole.student,
        actorId: 'student_3',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_7_1', dayOfWeek: 2, startTime: '14:00', endTime: '15:00'),
        ],
        message: '학원 바이올린 레슨 요청',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 8. 복수 악기 - 피아노 (같은 학생) — negotiating, 이벤트 4건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_8',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: _nextWeekday(today, 4),
          dayOfWeek: 4,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
      status: UnifiedRequestStatus.negotiating,
      currentRound: 2,
      createdAt: now.subtract(const Duration(days: 2)),
    ));
    _addEvents('ulr_8', [
      RequestEvent(
        id: 'evt_8_1',
        requestId: 'ulr_8',
        actorType: ProposerRole.student,
        actorId: 'student_1',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_8_init_1', dayOfWeek: 4, startTime: '16:00', endTime: '17:00'),
        ],
        message: '피아노도 배우고 싶습니다',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      RequestEvent(
        id: 'evt_8_2',
        requestId: 'ulr_8',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_8_1', dayOfWeek: 3, startTime: '17:00', endTime: '18:00'),
        ],
        message: '목요일은 바이올린이 있어서 수요일은 어떨까요?',
        createdAt: now.subtract(const Duration(days: 1, hours: 18)),
      ),
      RequestEvent(
        id: 'evt_8_3',
        requestId: 'ulr_8',
        actorType: ProposerRole.student,
        actorId: 'student_1',
        eventType: RequestEventType.counterPropose,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_8_2', dayOfWeek: 5, startTime: '15:00', endTime: '16:00'),
        ],
        message: '수요일은 학원이 있어서 금요일이 좋겠어요',
        createdAt: now.subtract(const Duration(days: 1, hours: 12)),
      ),
      RequestEvent(
        id: 'evt_8_4',
        requestId: 'ulr_8',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_8_3', dayOfWeek: 5, startTime: '15:00', endTime: '16:00'),
          TimeSlotOption(id: 'ts_8_4', dayOfWeek: 5, startTime: '16:00', endTime: '17:00'),
        ],
        message: '금요일 3시나 4시 중 선택해주세요',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 9. 회차권 + 정규 동시 진행 — package, pending, 이벤트 1건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_9',
      studentId: 'student_2',
      teacherId: 'teacher_1',
      type: LessonRequestType.package,
      instrument: '피아노',
      goal: UnifiedLessonGoal.exam,
      experience: UnifiedExperienceLevel.intermediate,
      message: '입시 대비 추가 회차권 요청',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: now.add(const Duration(days: 3)),
          startTime: '10:00',
          endTime: '11:00',
        ),
        PreferredTimeSlot(
          priority: 2,
          date: now.add(const Duration(days: 5)),
          startTime: '10:00',
          endTime: '11:00',
        ),
      ],
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 2)),
    ));
    _addEvents('ulr_9', [
      RequestEvent(
        id: 'evt_9_1',
        requestId: 'ulr_9',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_9_1', dayOfWeek: 0, startTime: '10:00', endTime: '11:00'),
          TimeSlotOption(id: 'ts_9_2', dayOfWeek: 0, startTime: '10:00', endTime: '11:00'),
        ],
        message: '입시 대비 추가 회차권 요청',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 10. 재수강 (학원) — negotiating, 이벤트 3건
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_10',
      studentId: 'student_7',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.intermediate,
      message: '다시 시작하고 싶습니다',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: _nextWeekday(today, 2),
          dayOfWeek: 2,
          startTime: '15:00',
          endTime: '16:00',
        ),
      ],
      isReturningStudent: true,
      academyId: 'academy_1',
      status: UnifiedRequestStatus.negotiating,
      currentRound: 1,
      createdAt: now.subtract(const Duration(days: 1, hours: 6)),
    ));
    _addEvents('ulr_10', [
      RequestEvent(
        id: 'evt_10_1',
        requestId: 'ulr_10',
        actorType: ProposerRole.student,
        actorId: 'student_7',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_10_init_1', dayOfWeek: 2, startTime: '15:00', endTime: '16:00'),
        ],
        message: '다시 시작하고 싶습니다',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      RequestEvent(
        id: 'evt_10_2',
        requestId: 'ulr_10',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_10_1', dayOfWeek: 1, startTime: '16:00', endTime: '17:00'),
          TimeSlotOption(id: 'ts_10_2', dayOfWeek: 3, startTime: '15:00', endTime: '16:00'),
        ],
        message: '화요일은 꽉 차서 다른 시간 제안드립니다',
        createdAt: now.subtract(const Duration(hours: 22)),
      ),
      RequestEvent(
        id: 'evt_10_3',
        requestId: 'ulr_10',
        actorType: ProposerRole.student,
        actorId: 'student_7',
        eventType: RequestEventType.counterPropose,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_10_3', dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
        ],
        message: '수요일 4시가 좋겠습니다',
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 11. Conflict scenario — preferred slot overlaps with confirmed lesson
    //     student_3 wants Mon 10:00 (conflicts with student_1's confirmed lesson)
    //     + Wed 14:00 (conflicts with student_2's preview lesson)
    //     + Fri 16:00 (no conflict)
    // ─────────────────────────────────────────────────────────────────────────
    final nextMon = _nextWeekday(today, 1);
    final nextWed = _nextWeekday(today, 3);
    final nextFri = _nextWeekday(today, 5);

    _addRequest(UnifiedLessonRequest(
      id: 'ulr_11',
      studentId: 'student_3',
      teacherId: 'teacher_1',
      type: LessonRequestType.trial,
      instrument: '첼로',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      message: '첼로를 처음 배우고 싶습니다. 시간 맞춰주세요!',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: nextMon,
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '11:00',
        ),
        PreferredTimeSlot(
          priority: 2,
          date: nextWed,
          dayOfWeek: 3,
          startTime: '14:00',
          endTime: '15:00',
        ),
        PreferredTimeSlot(
          priority: 3,
          date: nextFri,
          dayOfWeek: 5,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 2)),
    ));
    _addEvents('ulr_11', [
      RequestEvent(
        id: 'evt_11_1',
        requestId: 'ulr_11',
        actorType: ProposerRole.student,
        actorId: 'student_3',
        eventType: RequestEventType.initialRequest,
        suggestedSlots: [
          TimeSlotOption(id: 'ts_11_1', dayOfWeek: 1, startTime: '10:00', endTime: '11:00'),
          TimeSlotOption(id: 'ts_11_2', dayOfWeek: 3, startTime: '14:00', endTime: '15:00'),
          TimeSlotOption(id: 'ts_11_3', dayOfWeek: 5, startTime: '16:00', endTime: '17:00'),
        ],
        message: '첼로를 처음 배우고 싶습니다. 시간 맞춰주세요!',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);

    // ─────────────────────────────────────────────────────────────────────────
    // 12. 레슨 진행 중 (Phase 3) — inProgress, 3회차 완료
    // ─────────────────────────────────────────────────────────────────────────
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_12',
      studentId: 'student_2',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.major,
      experience: UnifiedExperienceLevel.intermediate,
      message: '피아노 입시 준비 레슨 희망합니다',
      preferredDuration: 60,
      preferredSlots: [
        PreferredTimeSlot(
          priority: 1,
          date: today.subtract(const Duration(days: 28)),
          dayOfWeek: 6,
          startTime: '10:00',
          endTime: '11:00',
        ),
      ],
      status: UnifiedRequestStatus.inProgress,
      confirmedAt: today.subtract(const Duration(days: 25)),
      createdAt: today.subtract(const Duration(days: 30)),
    ));
    _addEvents('ulr_12', [
      // Phase 1 events (request → approval)
      RequestEvent(
        id: 'evt_12_1',
        requestId: 'ulr_12',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.initialRequest,
        message: '피아노 입시 준비 레슨 희망합니다',
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      RequestEvent(
        id: 'evt_12_2',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.approve,
        selectedSlotIndex: 0,
        createdAt: today.subtract(const Duration(days: 29)),
      ),
      // Phase 2 events (payment)
      RequestEvent(
        id: 'evt_12_3',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.paymentRequested,
        message: '정규 10회 수강권 결제를 안내드립니다',
        createdAt: today.subtract(const Duration(days: 28)),
      ),
      RequestEvent(
        id: 'evt_12_4',
        requestId: 'ulr_12',
        actorType: ProposerRole.student,
        actorId: 'student_2',
        eventType: RequestEventType.paymentConfirmed,
        message: '입금 완료했습니다',
        createdAt: today.subtract(const Duration(days: 27)),
      ),
      RequestEvent(
        id: 'evt_12_5',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.subscriptionIssued,
        message: '정규 10회 수강권이 발행되었습니다',
        createdAt: today.subtract(const Duration(days: 26)),
      ),
      // Phase 3 events (lesson progress)
      RequestEvent(
        id: 'evt_12_6',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.lessonCompleted,
        message: '1회차 레슨 완료 — 기초 스케일 연습',
        createdAt: today.subtract(const Duration(days: 21)),
      ),
      RequestEvent(
        id: 'evt_12_7',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.lessonCompleted,
        message: '2회차 레슨 완료 — 하논 1-5번',
        createdAt: today.subtract(const Duration(days: 14)),
      ),
      RequestEvent(
        id: 'evt_12_8',
        requestId: 'ulr_12',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.lessonCompleted,
        message: '3회차 레슨 완료 — 체르니 100 시작',
        createdAt: today.subtract(const Duration(days: 7)),
      ),
    ]);
  }

  void _addRequest(UnifiedLessonRequest request) {
    _requests[request.id] = request;
  }

  void _addEvents(String requestId, List<RequestEvent> events) {
    _events[requestId] = events;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Repository interface implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requests[request.id] = request;
    return request;
  }

  @override
  Future<UnifiedLessonRequest?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _requests[id];
  }

  @override
  Future<List<UnifiedLessonRequest>> getByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values
        .where((r) => r.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<UnifiedLessonRequest>> getByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<UnifiedLessonRequest>> getPendingByTeacherId(
    String teacherId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values
        .where((r) =>
            r.teacherId == teacherId &&
            r.status == UnifiedRequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requests[request.id] = request;
    return request;
  }

  @override
  Future<UnifiedLessonRequest> approve(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.approved,
      confirmedAt: DateTime.now(),
    );
    _requests[id] = updated;
    return updated;
  }

  @override
  Future<UnifiedLessonRequest> withdrawApproval(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.pending,
    );
    _requests[id] = updated;
    return updated;
  }

  @override
  Future<UnifiedLessonRequest> reject(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.rejected,
      rejectionReason: reason ?? '현재 가능한 시간이 없어 이번에는 어렵습니다.',
    );
    _requests[id] = updated;
    return updated;
  }

  @override
  Future<UnifiedLessonRequest> proposeAlternatives(
    String id, {
    required List<TimeSlotOption> slots,
    String? message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.negotiating,
      currentRound: request.currentRound + 1,
    );
    _requests[id] = updated;

    // Add event
    await addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: id,
      actorType: ProposerRole.teacher,
      actorId: request.teacherId,
      eventType: RequestEventType.proposeAlternative,
      suggestedSlots: slots,
      message: message,
      createdAt: DateTime.now(),
    ));

    return updated;
  }

  @override
  Future<UnifiedLessonRequest> acceptAlternative(
    String id, {
    required int selectedSlotIndex,
    String? message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.timeConfirmed,
      confirmedAt: DateTime.now(),
    );
    _requests[id] = updated;

    await addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: id,
      actorType: ProposerRole.student,
      actorId: request.studentId,
      eventType: RequestEventType.acceptAlternative,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
      createdAt: DateTime.now(),
    ));

    return updated;
  }

  @override
  Future<UnifiedLessonRequest> counterPropose(
    String id, {
    required TimeSlotOption slot,
    String? message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) throw Exception('Request not found: $id');
    final updated = request.copyWith(
      currentRound: request.currentRound + 1,
    );
    _requests[id] = updated;

    await addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: id,
      actorType: ProposerRole.student,
      actorId: request.studentId,
      eventType: RequestEventType.counterPropose,
      suggestedSlots: [slot],
      message: message,
      createdAt: DateTime.now(),
    ));

    return updated;
  }
}
