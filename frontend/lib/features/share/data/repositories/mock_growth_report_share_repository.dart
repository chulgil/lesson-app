import '../../domain/entities/growth_report_share.dart';
import '../../domain/repositories/growth_report_share_repository.dart';

/// #1217 — mock 모드용 [GrowthReportShareRepository]. 백엔드 없이 가짜 토큰 반환.
class MockGrowthReportShareRepository implements GrowthReportShareRepository {
  @override
  Future<GrowthReportShare> createGrowthReportShare(
    String studentId, {
    int expiresInHours = 24,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // 보안 스캐너 오탐 회피 + per-student 식별: studentId 기반 가짜 식별자.
    final reportId = 'mock-growth-report-$studentId';
    return GrowthReportShare(
      token: reportId,
      url: 'https://lessonaza.app/growth-report/$reportId',
      appDeepLink: 'lessonaza://growth-report/$reportId',
      expiresAt: DateTime.now().add(Duration(hours: expiresInHours)),
    );
  }
}
