/// 스포트라이트 종류 — 학생 축하 overlay 1슬롯의 출처.
///
/// 스펙 §5.2 — 3종.
enum SpotlightType {
  /// 선생님이 teaching_resource 로 추가한 영상·곡 추천.
  teacherRec,

  /// 시즌·명절 큐레이션 (봄/추석/크리스마스/어린이날 등).
  seasonEvent,

  /// 자가 routine 30일+ 보유 학생에게 routine 추천.
  routineSuggestion;

  /// 직렬화 안정 — JSON 에 [name] 그대로 저장.
  static SpotlightType fromName(String n) => SpotlightType.values.firstWhere(
    (t) => t.name == n,
    orElse: () => throw ArgumentError.value(n, 'name', 'Unknown SpotlightType'),
  );
}
