import '../entities/lesson_summary_share.dart';

/// #808 — 레슨 요약 공유 토큰 발급 repository.
abstract class LessonSummaryShareRepository {
  /// 교사 소유 레슨의 공개 요약 공유 토큰을 발급한다.
  Future<LessonSummaryShare> createLessonSummaryShare(
    String lessonId, {
    int expiresInHours = 24,
  });
}
