import '../../domain/entities/lesson_request.dart';
import '../../domain/repositories/lesson_request_repository.dart';

/// Mock implementation of LessonRequestRepository with sample data.
class MockLessonRequestRepository implements LessonRequestRepository {
  final Map<String, LessonRequest> _requests = {};

  MockLessonRequestRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // ============================================================
    // 선생님 1 (teacher_1)이 받은 레슨 요청들
    // ============================================================

    // 요청 1: 체험 레슨 후 정규 레슨 신청 (pending - 대기 중)
    final request1 = LessonRequest(
      id: 'req_1',
      studentId: 'student_4', // 체험(trial) 학생
      teacherId: 'teacher_1',
      message: '체험 레슨이 너무 좋았어요! 정규 레슨 시작하고 싶습니다.',
      preferredTiming: PreferredStartTiming.nextWeek,
      keepPreviousSchedule: false,
      previousLessonDay: 2, // 화요일
      previousLessonTime: '15:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
      expiresAt: now.add(const Duration(days: 7) - const Duration(hours: 3)),
    );
    _requests[request1.id] = request1;

    // 요청 2: 오래된 학생 재등록 요청 (pending)
    final request2 = LessonRequest(
      id: 'req_2',
      studentId: 'student_5', // past 상태 학생
      teacherId: 'teacher_1',
      message: '6개월 만에 다시 연락드립니다. 바이올린이 너무 그리워서요.',
      preferredTiming: PreferredStartTiming.afterConsultation,
      keepPreviousSchedule: false, // 새 시간 상담 원함
      previousLessonDay: 6, // 토요일
      previousLessonTime: '14:00',
      previousLessonDuration: 50,
      status: LessonRequestStatus.pending,
      createdAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 6)),
    );
    _requests[request2.id] = request2;

    // 요청 3: 수강권 제안 완료된 요청
    final request3 = LessonRequest(
      id: 'req_3',
      studentId: 'student_6',
      teacherId: 'teacher_1',
      message: '다음 달부터 다시 시작하고 싶어요',
      preferredTiming: PreferredStartTiming.nextMonth,
      keepPreviousSchedule: true,
      previousLessonDay: 4, // 목요일
      previousLessonTime: '17:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.proposalSent,
      createdAt: now.subtract(const Duration(days: 3)),
      expiresAt: now.add(const Duration(days: 4)),
      proposalId: 'proposal_confirmed_1', // 연결된 수강권 제안 (student_6)
      statusUpdatedAt: now.subtract(const Duration(days: 2)),
    );
    _requests[request3.id] = request3;

    // 요청 4: 거절된 요청 (선생님 스케줄 없음)
    final request4 = LessonRequest(
      id: 'req_4',
      studentId: 'student_7',
      teacherId: 'teacher_1',
      message: '토요일 오전에 레슨 가능할까요?',
      preferredTiming: PreferredStartTiming.nextWeek,
      keepPreviousSchedule: false,
      previousLessonDay: 6,
      previousLessonTime: '10:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.declined,
      createdAt: now.subtract(const Duration(days: 5)),
      expiresAt: now.add(const Duration(days: 2)),
      declineReason: '죄송합니다. 현재 토요일 오전은 스케줄이 꽉 차서 어렵습니다. 오후 시간은 어떠세요?',
      statusUpdatedAt: now.subtract(const Duration(days: 4)),
    );
    _requests[request4.id] = request4;

    // 요청 5: 만료된 요청
    final request5 = LessonRequest(
      id: 'req_5',
      studentId: 'student_8',
      teacherId: 'teacher_1',
      message: '',
      preferredTiming: PreferredStartTiming.nextWeek,
      keepPreviousSchedule: true,
      previousLessonDay: 3, // 수요일
      previousLessonTime: '16:00',
      previousLessonDuration: 45,
      status: LessonRequestStatus.expired,
      createdAt: now.subtract(const Duration(days: 10)),
      expiresAt: now.subtract(const Duration(days: 3)),
      statusUpdatedAt: now.subtract(const Duration(days: 3)),
    );
    _requests[request5.id] = request5;

    // ============================================================
    // 선생님 2 (teacher_2)가 받은 레슨 요청
    // ============================================================

    final request6 = LessonRequest(
      id: 'req_6',
      studentId: 'student_4',
      teacherId: 'teacher_2',
      message: '피아노 레슨 다시 받고 싶습니다',
      preferredTiming: PreferredStartTiming.nextWeek,
      keepPreviousSchedule: true,
      previousLessonDay: 5, // 금요일
      previousLessonTime: '18:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 5)),
      expiresAt: now.add(const Duration(days: 7) - const Duration(hours: 5)),
    );
    _requests[request6.id] = request6;

    // ============================================================
    // 학생 1 (student_1)이 보낸 레슨 요청들 (학생 앱 테스트용)
    // ============================================================

    // 요청 7: student_1이 보낸 요청 (대기 중)
    final request7 = LessonRequest(
      id: 'req_7',
      studentId: 'student_1',
      teacherId: 'teacher_3',
      message: '다시 레슨 받고 싶습니다!',
      preferredTiming: PreferredStartTiming.nextWeek,
      keepPreviousSchedule: true,
      previousLessonDay: 3, // 수요일
      previousLessonTime: '16:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 12)),
      expiresAt: now.add(const Duration(days: 6, hours: 12)),
    );
    _requests[request7.id] = request7;

    // 요청 8: student_1이 보낸 요청 (수강권 제안 받음)
    final request8 = LessonRequest(
      id: 'req_8',
      studentId: 'student_1',
      teacherId: 'teacher_4',
      message: '첼로 레슨 다시 시작하고 싶어요',
      preferredTiming: PreferredStartTiming.nextMonth,
      keepPreviousSchedule: true,
      previousLessonDay: 1, // 월요일
      previousLessonTime: '14:00',
      previousLessonDuration: 50,
      status: LessonRequestStatus.proposalSent,
      createdAt: now.subtract(const Duration(days: 2)),
      expiresAt: now.add(const Duration(days: 5)),
      proposalId: 'proposal_auto_1', // 연결된 수강권 제안 (student_1)
      statusUpdatedAt: now.subtract(const Duration(days: 1)),
    );
    _requests[request8.id] = request8;

    // 요청 9: student_1이 보낸 요청 (보류됨)
    final request9 = LessonRequest(
      id: 'req_9',
      studentId: 'student_1',
      teacherId: 'teacher_5',
      message: '시간이 되시면 연락 부탁드려요',
      preferredTiming: PreferredStartTiming.afterConsultation,
      keepPreviousSchedule: false,
      previousLessonDay: 4, // 목요일
      previousLessonTime: '17:00',
      previousLessonDuration: 60,
      status: LessonRequestStatus.declined,
      createdAt: now.subtract(const Duration(days: 5)),
      expiresAt: now.add(const Duration(days: 2)),
      declineReason: '현재 스케줄이 꽉 차서 다음 달에 연락드릴게요!',
      statusUpdatedAt: now.subtract(const Duration(days: 3)),
    );
    _requests[request9.id] = request9;
  }

  @override
  Future<LessonRequest> create(LessonRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requests[request.id] = request;
    return request;
  }

  @override
  Future<LessonRequest?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _requests[id];
  }

  @override
  Future<List<LessonRequest>> getByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values.where((r) => r.teacherId == teacherId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LessonRequest>> getByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values.where((r) => r.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LessonRequest>> getPendingByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.values
        .where(
          (r) =>
              r.teacherId == teacherId &&
              r.status == LessonRequestStatus.pending &&
              !r.isExpired,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<LessonRequest?> getActiveRequest({
    required String studentId,
    required String teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _requests.values.firstWhere(
        (r) =>
            r.studentId == studentId && r.teacherId == teacherId && r.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonRequest> update(LessonRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requests[request.id] = request;
    return request;
  }

  @override
  Future<LessonRequest> updateStatus({
    required String id,
    required LessonRequestStatus status,
    String? proposalId,
    String? declineReason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _requests[id];
    if (request == null) {
      throw Exception('Request not found: $id');
    }

    final updated = request.copyWith(
      status: status,
      proposalId: proposalId ?? request.proposalId,
      declineReason: declineReason ?? request.declineReason,
      statusUpdatedAt: DateTime.now(),
    );
    _requests[id] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _requests.remove(id);
  }

  @override
  Future<int> processExpiredRequests() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    int count = 0;

    for (final request in _requests.values.toList()) {
      if (request.status == LessonRequestStatus.pending &&
          now.isAfter(request.expiresAt)) {
        _requests[request.id] = request.copyWith(
          status: LessonRequestStatus.expired,
          statusUpdatedAt: now,
        );
        count++;
      }
    }
    return count;
  }
}
