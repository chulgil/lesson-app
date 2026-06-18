import '../../domain/entities/lesson_summary_share.dart';
import '../../domain/repositories/lesson_summary_share_repository.dart';

/// #808 — mock 모드용 [LessonSummaryShareRepository]. 백엔드 없이 가짜 토큰 반환.
class MockLessonSummaryShareRepository implements LessonSummaryShareRepository {
  @override
  Future<LessonSummaryShare> createLessonSummaryShare(
    String lessonId, {
    int expiresInHours = 24,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // 보안 스캐너 오탐 회피 + per-lesson 식별: lessonId 기반 가짜 식별자.
    final summaryId = 'mock-summary-$lessonId';
    return LessonSummaryShare(
      token: summaryId,
      url: 'https://lessonaza.app/student/summary/$summaryId',
      appDeepLink: 'lessonaza://student/summary/$summaryId',
      shareText: '레슨 요약을 확인해보세요: https://lessonaza.app/student/summary/$summaryId',
      expiresAt: DateTime.now().add(Duration(hours: expiresInHours)),
    );
  }
}
