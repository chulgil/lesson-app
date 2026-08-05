import '../entities/growth_report_share.dart';

/// #1217 — 자녀 성장 리포트 공유 토큰 발급 repository.
abstract class GrowthReportShareRepository {
  /// 교사 소유 학생의 공개 성장 리포트 공유 토큰을 발급한다.
  Future<GrowthReportShare> createGrowthReportShare(
    String studentId, {
    int expiresInHours = 24,
  });
}
