import '../entities/bulk_closure.dart';

/// G15 학원장 일괄 휴강 — 강사 시점 Repository.
///
/// 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5.
/// 강사 본인이 영향 받는 closure 만 조회·작용한다.
abstract class BulkClosureRepository {
  /// 강사 본인이 영향 받는 closure 목록 (최신순).
  /// 강사 시점 알림함/대시보드에서 사용.
  Future<List<BulkClosure>> listByTeacherMember(String teacherMemberId);

  /// closure 상세.
  Future<BulkClosure?> getById(String closureId);

  /// 강사 의견 입력 (1시간 의견 윈도우 동안만 허용).
  ///
  /// `BulkClosure.isOpinionWindowOpen == false` 또는
  /// status != [ClosureStatus.proposed] 일 때 예외.
  Future<void> submitTeacherOpinion(String closureId, String comment);

  /// 적용된 closure 의 영향 레슨에 보강 시각 일괄 저장.
  ///
  /// key: lessonId, value: 보강 시각.
  /// status != [ClosureStatus.applied] 일 때 예외.
  Future<void> submitMakeupSchedule(
    String closureId,
    Map<String, DateTime> makeupByLessonId,
  );
}
