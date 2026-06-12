import '../entities/spotlight_prompt.dart';
import '../entities/spotlight_type.dart';
import '../repositories/spotlight_prompt_repository.dart';

/// 스포트라이트 큐 시드 — 3 generator (teacherRec / seasonEvent / routineSuggestion).
///
/// 플랜 Job 8. 각 generator 는 중복 차단 (deterministic id) 후 [enqueue].
/// P3 routineSuggestion 은 30일+ 스트릭 단순 조건 placeholder — 정밀 패턴 분석
/// 은 P4.
class SpotlightSeedingService {
  SpotlightSeedingService(this._repo);

  final SpotlightPromptRepository _repo;

  /// routineSuggestion 시드 최소 스트릭 (스펙 §5.2).
  static const int routineSuggestionMinStreakDays = 30;

  static String teacherRecId(String teacherResourceId) =>
      'teacher_rec:$teacherResourceId';

  static String seasonEventId(String seasonKey) => 'season:$seasonKey';

  static String routineSuggestionId(String studentId) => 'routine:$studentId';

  /// 선생님이 추가한 teaching_resource 등록 시 호출.
  ///
  /// [isMandatory] = true 면 큐 우선순위 +10 진입 (스펙 §5.2 — 선생님 UI 토글).
  /// 학생 UI 에는 동일한 "선생님이 추천했어요" 메시지 (origin 라벨 0).
  ///
  /// 같은 [teacherResourceId] 가 이미 큐에 있으면 no-op (중복 차단).
  Future<bool> seedTeacherRecommendation({
    required String studentId,
    required String teacherResourceId,
    required String title,
    required DateTime now,
    String? videoId,
    String? ctaRoute,
    bool isMandatory = false,
  }) async {
    final id = teacherRecId(teacherResourceId);
    if (await _existsInQueue(id)) return false;
    await _repo.enqueue(
      SpotlightPrompt(
        id: id,
        studentId: studentId,
        type: SpotlightType.teacherRec,
        title: title,
        videoId: videoId,
        ctaRoute: ctaRoute,
        queuedAt: now,
        isMandatory: isMandatory,
      ),
    );
    return true;
  }

  /// 활성 시즌 진입 시 호출 (Job 8 Task 8.3 큐레이터).
  ///
  /// 같은 [seasonKey] 가 이미 큐에 있으면 no-op (중복 차단).
  Future<bool> seedSeasonEvent({
    required String studentId,
    required String seasonKey,
    required String title,
    required DateTime now,
    String? ctaRoute,
  }) async {
    final id = seasonEventId(seasonKey);
    if (await _existsInQueue(id)) return false;
    await _repo.enqueue(
      SpotlightPrompt(
        id: id,
        studentId: studentId,
        type: SpotlightType.seasonEvent,
        title: title,
        ctaRoute: ctaRoute,
        queuedAt: now,
      ),
    );
    return true;
  }

  /// 학생당 1회 시드 — 스트릭 30일+ 도달 시 routine 추천.
  ///
  /// [recentStreakDays] < 30 → no-op. 학생당 routine 1개만 (중복 차단).
  Future<bool> seedRoutineSuggestion({
    required String studentId,
    required int recentStreakDays,
    required DateTime now,
  }) async {
    if (recentStreakDays < routineSuggestionMinStreakDays) return false;
    final id = routineSuggestionId(studentId);
    if (await _existsInQueue(id)) return false;
    await _repo.enqueue(
      SpotlightPrompt(
        id: id,
        studentId: studentId,
        type: SpotlightType.routineSuggestion,
        title: '꾸준한 루틴이 한 달 넘었어요. 새로운 루틴 어때요?',
        queuedAt: now,
      ),
    );
    return true;
  }

  Future<bool> _existsInQueue(String id) async {
    final existing = await _repo.getById(id);
    return existing != null;
  }
}
