/// 도장 강도 임계값. 연습 durationMinutes >= fullMinutes 이면 full, 아니면 short.
/// NOTE: 실행 시 practice 도메인의 기존 임계값과 정합 확인(없으면 이 값 사용 — 스펙 §8.2).
class JournalThresholds {
  const JournalThresholds._();
  static const int fullMinutes = 10;
}
