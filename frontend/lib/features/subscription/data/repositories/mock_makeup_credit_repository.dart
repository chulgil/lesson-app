import '../../domain/entities/makeup_credit.dart';
import '../../domain/repositories/makeup_credit_repository.dart';

/// In-memory mock for makeup credits (#432).
///
/// 적립(휴가/노쇼/일괄변경)·사용·만료는 BE 책임. 본 Mock 은 FE UI 검증용으로
/// 샘플 크레딧을 제공하고 수동 발급/회수만 로컬에서 반영한다.
class MockMakeupCreditRepository implements MakeupCreditRepository {
  MockMakeupCreditRepository() {
    final now = DateTime.now();
    _credits.addAll([
      MakeupCredit(
        id: 'mock-credit-1',
        studentId: 'mock-student-1',
        teacherId: 'mock-teacher',
        reason: MakeupCreditReason.teacherVacation,
        createdAt: now.subtract(const Duration(days: 5)),
        expiresAt: now.add(const Duration(days: 25)),
        sourceEventId: 'mock-vacation-1',
      ),
      MakeupCredit(
        id: 'mock-credit-2',
        studentId: 'mock-student-1',
        teacherId: 'mock-teacher',
        reason: MakeupCreditReason.noShowExempt,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 28)),
        sourceEventId: 'mock-lesson-9',
      ),
      MakeupCredit(
        id: 'mock-credit-3',
        studentId: 'mock-student-1',
        teacherId: 'mock-teacher',
        reason: MakeupCreditReason.bulkChangeLoss,
        createdAt: now.subtract(const Duration(days: 20)),
        expiresAt: now.add(const Duration(days: 10)),
        usedAt: now.subtract(const Duration(days: 3)),
        usedLessonId: 'mock-lesson-12',
      ),
    ]);
  }

  final List<MakeupCredit> _credits = [];

  @override
  Future<List<MakeupCredit>> listStudentCredits() async {
    // TODO(remote): scope to the signed-in student id from auth.
    return _sortedCopy();
  }

  @override
  Future<List<MakeupCredit>> listTeacherCredits({
    required String studentId,
  }) async {
    return _credits.where((c) => c.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<MakeupCredit> grantCredit({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
  }) async {
    final now = DateTime.now();
    final credit = MakeupCredit(
      id: 'mock-credit-${now.microsecondsSinceEpoch}',
      studentId: studentId,
      teacherId: 'mock-teacher',
      sourceSubscriptionId: sourceSubscriptionId,
      reason: MakeupCreditReason.manualGrant,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );
    _credits.add(credit);
    return credit;
  }

  @override
  Future<void> revokeCredit(String creditId) async {
    final index = _credits.indexWhere((c) => c.id == creditId);
    if (index == -1) {
      throw Exception('Makeup credit not found: $creditId');
    }
    if (_credits[index].isUsed) {
      throw Exception('이미 사용된 크레딧은 회수할 수 없어요.');
    }
    _credits.removeAt(index);
  }

  @override
  Future<MakeupCredit> useCredit({
    required String creditId,
    required String lessonId,
  }) async {
    final index = _credits.indexWhere((c) => c.id == creditId);
    if (index == -1) {
      throw Exception('Makeup credit not found: $creditId');
    }
    final credit = _credits[index];
    if (credit.isUsed) {
      throw Exception('이미 사용된 크레딧이에요.');
    }
    if (credit.isExpired(DateTime.now())) {
      throw Exception('만료된 크레딧은 사용할 수 없어요.');
    }
    final used = credit.copyWith(
      usedAt: DateTime.now(),
      usedLessonId: lessonId,
    );
    _credits[index] = used;
    return used;
  }

  List<MakeupCredit> _sortedCopy() {
    return [..._credits]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
