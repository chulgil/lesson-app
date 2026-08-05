import 'daily_mission_kind.dart';

/// 데일리 미션 1건 — 관측된 진행값(progress)과 목표(target), 완료 여부.
///
/// 스펙: doc 46 §4④. progress/target 은 기존 관측 신호(연습분·도구사용
/// 횟수)에서만 파생한다 — 신규 트래킹 파이프라인 없음. [completed] 는
/// derived(progress>=target) 값에 완료 원장(ledger)을 OR 결합한 결과 — 한
/// 번 완료되면 신호가 흔들려도(예: 목표를 상향 조정해 derived 가 다시
/// false 로 바뀌어도) 그날(KST) 안에서는 계속 완료 상태를 유지한다.
class DailyMission {
  final DailyMissionKind kind;
  final int target;
  final int progress;
  final bool completed;

  const DailyMission({
    required this.kind,
    required this.target,
    required this.progress,
    required this.completed,
  });

  /// 0.0~1.0 진행률 — 진행바/스탬프 표시용. 100% 상한(clamp), 초과분 누적 없음.
  double get ratio => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
}
