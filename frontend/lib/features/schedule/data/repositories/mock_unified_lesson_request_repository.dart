import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';

/// Mock implementation of UnifiedLessonRequestRepository for development.
class MockUnifiedLessonRequestRepository
    implements UnifiedLessonRequestRepository {
  final Map<String, UnifiedLessonRequest> _requests = {};

  MockUnifiedLessonRequestRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    // Pending trial request
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      type: LessonRequestType.trial,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      message: '바이올린을 처음 배우고 싶습니다',
      preferredDay: 1, // 화
      preferredTime: '14:00',
      preferredDuration: 60,
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
    ));

    // Approved regular request
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_2',
      studentId: 'student_2',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.exam,
      experience: UnifiedExperienceLevel.intermediate,
      message: '입시 준비 중입니다',
      preferredDay: 3, // 목
      preferredTime: '16:00',
      preferredDuration: 60,
      status: UnifiedRequestStatus.approved,
      createdAt: now.subtract(const Duration(days: 1)),
      confirmedAt: now.subtract(const Duration(hours: 12)),
    ));

    // Rejected request
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_3',
      studentId: 'student_3',
      teacherId: 'teacher_1',
      type: LessonRequestType.trial,
      instrument: '비올라',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      preferredDay: 5, // 토
      preferredTime: '10:00',
      preferredDuration: 30,
      status: UnifiedRequestStatus.rejected,
      rejectionReason: '스케줄이 꽉 차서 다음에 신청해주세요',
      createdAt: now.subtract(const Duration(days: 2)),
    ));

    // Returning student request
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_4',
      studentId: 'student_4',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.intermediate,
      message: '다시 시작하고 싶습니다',
      preferredDay: 2, // 수
      preferredTime: '15:00',
      preferredDuration: 60,
      isReturningStudent: true,
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 5)),
    ));

    // Negotiating request (teacher proposed 3 alternatives)
    _addRequest(UnifiedLessonRequest(
      id: 'ulr_5',
      studentId: 'student_5',
      teacherId: 'teacher_1',
      type: LessonRequestType.trial,
      instrument: '첼로',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      message: '첼로를 배우고 싶습니다',
      preferredDay: 0, // 월
      preferredTime: '09:00',
      preferredDuration: 60,
      status: UnifiedRequestStatus.negotiating,
      currentRound: 1,
      proposals: [
        TimeProposal(
          id: 'tp_1',
          proposerId: 'teacher_1',
          role: ProposerRole.teacher,
          action: ProposalAction.propose,
          slots: [
            TimeSlotOption(
              id: 'ts_1',
              dayOfWeek: 1,
              startTime: '15:00',
              endTime: '16:00',
            ),
            TimeSlotOption(
              id: 'ts_2',
              dayOfWeek: 3,
              startTime: '14:00',
              endTime: '15:00',
            ),
            TimeSlotOption(
              id: 'ts_3',
              dayOfWeek: 5,
              startTime: '10:00',
              endTime: '11:00',
            ),
          ],
          message: '월요일 9시는 다른 레슨이 있어요. 다른 시간 중 골라주세요!',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 4)),
    ));
  }

  void _addRequest(UnifiedLessonRequest request) {
    _requests[request.id] = request;
  }

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
    if (request == null) {
      throw Exception('Request not found: $id');
    }
    final updated = request.copyWith(
      status: UnifiedRequestStatus.approved,
      confirmedAt: DateTime.now(),
    );
    _requests[id] = updated;
    return updated;
  }

  @override
  Future<UnifiedLessonRequest> reject(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) {
      throw Exception('Request not found: $id');
    }
    final updated = request.copyWith(
      status: UnifiedRequestStatus.rejected,
      rejectionReason: reason ?? '스케줄이 꽉 차서 다음에 신청해주세요',
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
    if (request == null) {
      throw Exception('Request not found: $id');
    }

    final proposal = TimeProposal(
      id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
      proposerId: 'teacher_1',
      role: ProposerRole.teacher,
      action: ProposalAction.propose,
      slots: slots,
      message: message,
      createdAt: DateTime.now(),
    );

    final updated = request.copyWith(
      status: UnifiedRequestStatus.negotiating,
      proposals: [...request.proposals, proposal],
      currentRound: request.currentRound + 1,
    );
    _requests[id] = updated;
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
    if (request == null) {
      throw Exception('Request not found: $id');
    }

    final teacherProposals =
        request.proposals.where((p) => p.role == ProposerRole.teacher).toList();
    final latestTeacher = teacherProposals.last;
    final selectedSlot = latestTeacher.slots[selectedSlotIndex];

    final acceptProposal = TimeProposal(
      id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
      proposerId: 'student_1',
      role: ProposerRole.student,
      action: ProposalAction.accept,
      slots: [selectedSlot.copyWith(isSelected: true)],
      message: message,
      createdAt: DateTime.now(),
    );

    final updated = request.copyWith(
      status: UnifiedRequestStatus.timeConfirmed,
      proposals: [...request.proposals, acceptProposal],
      preferredDay: selectedSlot.dayOfWeek,
      preferredTime: selectedSlot.startTime,
      confirmedAt: DateTime.now(),
    );
    _requests[id] = updated;
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
    if (request == null) {
      throw Exception('Request not found: $id');
    }

    const maxRounds = 3;
    if (request.currentRound >= maxRounds) {
      final expired = request.copyWith(status: UnifiedRequestStatus.expired);
      _requests[id] = expired;
      return expired;
    }

    final counterProposal = TimeProposal(
      id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
      proposerId: 'student_1',
      role: ProposerRole.student,
      action: ProposalAction.counterPropose,
      slots: [slot],
      message: message,
      createdAt: DateTime.now(),
    );

    final updated = request.copyWith(
      proposals: [...request.proposals, counterProposal],
    );
    _requests[id] = updated;
    return updated;
  }
}
