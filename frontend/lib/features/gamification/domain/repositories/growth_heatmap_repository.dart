import '../entities/daily_practice.dart';
import '../entities/growth_heatmap.dart';

/// 성장 히트맵 저장소 인터페이스.
///
/// 스펙 §6.3 / 플랜 Job 2 Task 2.3. P1 구현체는
/// [MockGrowthHeatmapRepository] — 메모리(Hive 후속). P2 BE 도입.
abstract class GrowthHeatmapRepository {
  /// [studentId] 의 히트맵 조회. [yearsBack] = 1 이면 최근 1년 cells 만.
  Future<GrowthHeatmap> getHeatmap(String studentId, {int yearsBack = 1});

  /// 단일 일자의 [DailyPractice] 갱신.
  ///
  /// 같은 [date] (UTC 자정 정렬) 에 기존 evidence 가 있으면 5 필드 누적 합산
  /// (Plan 의 단일 진입점 호출 패턴 — Job 3 PracticeRecordingService 가
  /// 한 evidence 씩 호출).
  Future<void> recordPractice(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  );
}
