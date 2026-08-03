import '../entities/daily_mission_kind.dart';

/// 데일리 미션 로테이션 — 고정1([fixedCore]) + [pool] 에서 결정적으로 2개 선택.
///
/// 스펙: doc 46 §4④. 서버 없이 `hash(dateKST + studentId)` 로 결정적 로테이션
/// — 같은 KST 달력일에는 항상 같은 3개, KST 자정에만 바뀐다.
///
/// **드롭한 후보**: `section_5`("오늘 도장 5개"). [PracticeJournalRepository]
/// 의 `upsertMark` 는 날짜당 스탬프 1개(강도만 구분)이고, "5개" 카운트에
/// 대응하는 신호는 `PracticeRepertoire.dailyRepeatCounts`(곡·섹션별로 흩어져
/// 있음) 뿐이라 학생 전체를 가로지르는 단일 관측치가 없다 — 신규 집계
/// 파이프라인 없이는 얻을 수 없어 P3a 범위에서 제외했다.
class DailyMissionRotation {
  const DailyMissionRotation._();

  /// 고정 코어 — 매일 동일, 로테이션 대상 아님.
  static const DailyMissionKind fixedCore = DailyMissionKind.practice15m;

  /// 로테이션 풀 — 이 중 2개를 매일 결정적으로 선택.
  static const List<DailyMissionKind> pool = [
    DailyMissionKind.metronome1,
    DailyMissionKind.tuner1,
    DailyMissionKind.recording1,
  ];

  /// KST 시간대 오프셋 — [StreakFreezeService] 와 동일 컨벤션 (Asia/Seoul 고정,
  /// DST 없음).
  static const Duration _kstOffset = Duration(hours: 9);

  /// [instant] 를 KST 달력일(연/월/일)만 남긴 로컬 [DateTime] 으로 변환.
  ///
  /// 자정 리셋 계약: 같은 KST 달력일 안의 서로 다른 시각(예: 09:00 vs 23:00
  /// KST)은 항상 같은 결과를 반환한다.
  static DateTime kstCalendarDate(DateTime instant) {
    final kst = instant.toUtc().add(_kstOffset);
    return DateTime(kst.year, kst.month, kst.day);
  }

  /// [studentId] + [now] 의 KST 달력일 기준 오늘의 미션 3종(고정1+로테이션2)을
  /// 결정적으로 산출한다. 순서: [fixedCore] 먼저, 이후 로테이션 2개.
  static List<DailyMissionKind> missionsFor(String studentId, DateTime now) {
    final date = kstCalendarDate(now);
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final seed = _stableHash('$dateKey:$studentId');
    final excludeIndex = seed % pool.length;
    final rotating = [
      for (var i = 0; i < pool.length; i++)
        if (i != excludeIndex) pool[i],
    ];
    return [fixedCore, ...rotating];
  }

  /// 플랫폼(dart VM / dart2js 웹) 무관 결정적 문자열 해시.
  ///
  /// `String.hashCode` 는 Dart SDK 버전·컴파일 타깃에 따라 달라질 수 있는
  /// 명세되지 않은 구현이라 로테이션 안정성에 쓸 수 없다. 대신 Java
  /// `String.hashCode` 와 동일한 `hash = hash*31 + c` 점화식을 매 스텝
  /// 31비트로 마스킹하며 계산한다 — 중간값이 항상 2^53(JS Number 안전
  /// 정수 상한) 아래에 머물러 dart2js(웹)/dart VM(모바일) 어디서든 같은
  /// 결과를 보장한다.
  static int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
