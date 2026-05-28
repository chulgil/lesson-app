import 'package:lessonaza/features/academy/domain/entities/academy_activity_log.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_activity_repository.dart';

class MockAcademyActivityRepository implements AcademyActivityRepository {
  final Map<String, AcademyActivityLog> _logs = {
    'log_001': AcademyActivityLog(
      id: 'log_001',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'lesson_created',
      description: '레슨 1개 생성',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    'log_002': AcademyActivityLog(
      id: 'log_002',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'subscription_issued',
      description: '학생 이름에게 수강권 발급',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    'log_003': AcademyActivityLog(
      id: 'log_003',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'student_enrolled',
      description: '신규 학생 등록',
      createdAt: DateTime.now().subtract(const Duration(hours: 11)),
    ),
    'log_004': AcademyActivityLog(
      id: 'log_004',
      academyId: 'acad_001',
      actorMemberId: 'member_002',
      actorName: '이선생님',
      actionType: 'lesson_completed',
      description: '레슨 1개 완료',
      createdAt: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    'log_005': AcademyActivityLog(
      id: 'log_005',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'payment_confirmed',
      description: '입금 확인 완료',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    'log_006': AcademyActivityLog(
      id: 'log_006',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'schedule_changed',
      description: '레슨 일정 변경',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    'log_007': AcademyActivityLog(
      id: 'log_007',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'note_added',
      description: '학생 노트 추가',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    'log_008': AcademyActivityLog(
      id: 'log_008',
      academyId: 'acad_001',
      actorMemberId: 'member_002',
      actorName: '이선생님',
      actionType: 'student_enrolled',
      description: '신규 학생 등록',
      createdAt: DateTime.now().subtract(const Duration(hours: 24)),
    ),
    'log_009': AcademyActivityLog(
      id: 'log_009',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'lesson_request_accepted',
      description: '레슨 요청 수락',
      createdAt: DateTime.now().subtract(const Duration(hours: 0, minutes: 30)),
    ),
    'log_010': AcademyActivityLog(
      id: 'log_010',
      academyId: 'acad_001',
      actorMemberId: 'member_001',
      actorName: '김선생님',
      actionType: 'makeup_recorded',
      description: '보강 레슨 기록',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  };

  @override
  Future<List<AcademyActivityLog>> listByAcademyAndActor(
    String academyId,
    String actorMemberId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list =
        _logs.values
            .where(
              (log) =>
                  log.academyId == academyId &&
                  log.actorMemberId == actorMemberId,
            )
            .toList();
    // Sort by createdAt descending (newest first)
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
