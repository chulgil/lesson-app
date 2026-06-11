import '../entities/quest_origin.dart';
import '../entities/student_quest.dart';

/// 학생 자가 quest 저장소 인터페이스.
///
/// 스펙 §6.1 / 플랜 Job 2 Task 2.1. P1 구현체는 [MockStudentQuestRepository]
/// (Hive 로컬). P2 에서 BE 구현체 도입.
abstract class StudentQuestRepository {
  /// 미완료 + 기한 내 quest 목록 반환.
  Future<List<StudentQuest>> getActiveQuests(String studentId);

  /// 신규 quest 등록. 반환값은 저장된 quest (id 미지정 시 생성된 id 포함).
  Future<StudentQuest> createQuest(StudentQuest quest);

  /// 진척 갱신. [currentValue] 가 [StudentQuest.targetValue] 이상이어도
  /// `isCompleted` 자동 전환은 호출자(서비스 계층) 책임.
  Future<StudentQuest> updateProgress(String questId, int currentValue);

  /// 명시적 완료 표시. `isCompleted=true` + `completedAt=now`.
  Future<void> markCompleted(String questId);

  /// 특정 [origin] 으로 필터링한 quest 목록.
  Future<List<StudentQuest>> getQuestsByOrigin(
    String studentId,
    QuestOrigin origin,
  );
}
