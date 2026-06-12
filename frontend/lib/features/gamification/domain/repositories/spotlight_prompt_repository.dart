import '../entities/spotlight_prompt.dart';

/// 스포트라이트 프롬프트 저장소 인터페이스.
///
/// 스펙 §6.2 / 플랜 Job 2 Task 2.1. 구현체: [MockSpotlightPromptRepository]
/// (테스트), [HiveSpotlightPromptRepository] (런타임 — `Box<String>` + JSON,
/// key=`{studentId}::{id}`).
abstract class SpotlightPromptRepository {
  /// 새 프롬프트를 큐에 enqueue.
  ///
  /// 동일 [SpotlightPrompt.id] 가 이미 있으면 덮어쓴다 — Seeding 서비스의 중복
  /// 차단 책임 (Job 8 `SpotlightSeedingService.seed*` 가 동일 source 중복 검사).
  Future<void> enqueue(SpotlightPrompt prompt);

  /// [studentId] 의 모든 프롬프트 반환 (정렬 책임 없음 — Queue 서비스가 우선순위).
  ///
  /// 빈 큐 → 빈 리스트. 다른 학생 record 누출 0 (key prefix 격리).
  Future<List<SpotlightPrompt>> listForStudent(String studentId);

  /// [id] 로 단일 프롬프트 조회. 없으면 null.
  Future<SpotlightPrompt?> getById(String id);

  /// 노출 시각 갱신 — `lastShownAt = now`.
  Future<SpotlightPrompt> markShown(String id, DateTime now);

  /// "다음에" 거절 — `declineCount += 1` + `lastShownAt = now`.
  ///
  /// hideUntil/permanentlyHidden 결정은 호출자 책임 (Job 5
  /// `SpotlightDeclineLearningService`).
  Future<SpotlightPrompt> incrementDecline(String id, DateTime now);

  /// hide 시각 설정 — cooldown 7일 또는 8주 hide (Job 5).
  Future<SpotlightPrompt> setHideUntil(String id, DateTime until);

  /// 영구 hide — `permanentlyHidden = true` (8주 후 재거절 또는 accept 시).
  Future<SpotlightPrompt> markPermanentlyHidden(String id);
}
