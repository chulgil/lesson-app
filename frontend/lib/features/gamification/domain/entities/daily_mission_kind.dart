/// 데일리 미션 종류 — ESL 스타일 "오늘의 미션"(고정1 + 로테이션2, doc 46 §4④).
///
/// 순수 값 — 표시 라벨/아이콘은 `presentation/extensions` 에서 변환한다
/// (flutter-architecture 계약: domain 에 표시 getter 금지).
enum DailyMissionKind {
  /// 고정 코어 — 오늘의 연습 목표(분) 달성. [DailyPracticeGoal]과 동일 목표값.
  practice15m,

  /// 로테이션 풀 — 메트로놈 연습 1분 이상.
  metronome1,

  /// 로테이션 풀 — 튜너 연습 1분 이상.
  tuner1,

  /// 로테이션 풀 — 녹음 1회 이상.
  recording1,
}
