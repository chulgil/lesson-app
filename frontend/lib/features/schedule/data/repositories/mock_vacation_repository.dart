import '../../domain/entities/vacation_period.dart';
import '../../domain/repositories/vacation_repository.dart';

/// In-memory mock for offline / mock-mode runs (#431).
class MockVacationRepository implements VacationRepository {
  final List<VacationPeriod> _periods = [];

  @override
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Mock 영향 미리보기 — 실제 영향 계산은 BE 가 담당.
    // TODO(remote): GET /teacher/vacation/impact 로 대체.
    // 기간이 0일 이상이면 샘플 학생 N명을 노출해 미리보기 UI 를 검증한다.
    final days = endDate.difference(startDate).inDays;
    if (days < 0) {
      return VacationImpactPreview(
        startDate: startDate,
        endDate: endDate,
        impactedLessonCount: 0,
        impactedStudentCount: 0,
      );
    }
    const students = [
      VacationImpactedStudent(
        studentId: 'mock-student-1',
        studentName: '김민수',
        lessonCount: 2,
      ),
      VacationImpactedStudent(
        studentId: 'mock-student-2',
        studentName: '박서연',
        lessonCount: 3,
      ),
      VacationImpactedStudent(
        studentId: 'mock-student-3',
        studentName: '이지원',
        lessonCount: 2,
      ),
    ];
    final lessonCount = students.fold<int>(0, (sum, s) => sum + s.lessonCount);
    return VacationImpactPreview(
      startDate: startDate,
      endDate: endDate,
      impactedLessonCount: lessonCount,
      impactedStudentCount: students.length,
      impactedStudents: students,
    );
  }

  @override
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async {
    final now = DateTime.now();
    final period = VacationPeriod(
      id: 'mock-${now.microsecondsSinceEpoch}',
      teacherId: 'mock-teacher',
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      defaultDisposition: defaultDisposition,
      createdAt: now,
    );
    _periods.add(period);
    return period;
  }

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async {
    final filtered = includeCancelled
        ? _periods
        : _periods.where((p) => p.cancelledAt == null).toList();
    final sorted = [...filtered]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async {
    final index = _periods.indexWhere((p) => p.id == periodId);
    if (index == -1) {
      throw Exception('Vacation not found: $periodId');
    }
    final current = _periods[index];
    if (current.cancelledAt != null) {
      throw Exception('Vacation already cancelled');
    }
    final cancelled = VacationPeriod(
      id: current.id,
      teacherId: current.teacherId,
      startDate: current.startDate,
      endDate: current.endDate,
      reason: current.reason,
      defaultDisposition: current.defaultDisposition,
      cancelledAt: DateTime.now(),
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _periods[index] = cancelled;
    return cancelled;
  }
}
