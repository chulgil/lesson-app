import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';

StudentQuest _make({
  String id = 'q1',
  String studentId = 's1',
  QuestOrigin origin = QuestOrigin.selfCreated,
  bool isCompleted = false,
}) => StudentQuest(
  id: id,
  studentId: studentId,
  origin: origin,
  title: '스케일 5분',
  type: ChallengeType.practiceMinutes,
  targetValue: 5,
  currentValue: 0,
  startDate: DateTime(2026, 6, 11),
  endDate: DateTime(2026, 6, 18),
  isCompleted: isCompleted,
);

void main() {
  late MockStudentQuestRepository repo;

  setUp(() {
    repo = MockStudentQuestRepository();
  });

  group('createQuest', () {
    test('persists quest and returns it', () async {
      final saved = await repo.createQuest(_make(id: 'q1'));
      expect(saved.id, 'q1');
      final active = await repo.getActiveQuests('s1');
      expect(active.length, 1);
      expect(active.single.id, 'q1');
    });
  });

  group('getActiveQuests', () {
    test('returns only incomplete quests for the student', () async {
      await repo.createQuest(_make(id: 'q1', isCompleted: false));
      await repo.createQuest(_make(id: 'q2', isCompleted: true));
      await repo.createQuest(
        _make(id: 'q3', studentId: 's2', isCompleted: false),
      );
      final active = await repo.getActiveQuests('s1');
      expect(active.map((q) => q.id), ['q1']);
    });

    test('returns empty list when student has no quests', () async {
      final active = await repo.getActiveQuests('ghost');
      expect(active, isEmpty);
    });
  });

  group('updateProgress', () {
    test('updates currentValue without auto-completing', () async {
      await repo.createQuest(_make(id: 'q1'));
      final updated = await repo.updateProgress('q1', 5);
      expect(updated.currentValue, 5);
      expect(updated.isCompleted, false); // 자동 완료 X — 호출자 책임
    });

    test('throws when questId not found', () async {
      expect(() => repo.updateProgress('ghost', 5), throwsA(isA<StateError>()));
    });
  });

  group('markCompleted', () {
    test('sets isCompleted true and completedAt non-null', () async {
      await repo.createQuest(_make(id: 'q1'));
      await repo.markCompleted('q1');
      final active = await repo.getActiveQuests('s1');
      expect(active, isEmpty); // 완료 후엔 active 에서 빠짐
      final byOrigin = await repo.getQuestsByOrigin(
        's1',
        QuestOrigin.selfCreated,
      );
      expect(byOrigin.single.isCompleted, true);
      expect(byOrigin.single.completedAt, isNotNull);
    });
  });

  group('getQuestsByOrigin', () {
    test('filters by origin and student, includes completed', () async {
      await repo.createQuest(_make(id: 'q1', origin: QuestOrigin.selfCreated));
      await repo.createQuest(
        _make(id: 'q2', origin: QuestOrigin.systemRoutine),
      );
      await repo.createQuest(
        _make(id: 'q3', origin: QuestOrigin.selfCreated, isCompleted: true),
      );
      final selfCreated = await repo.getQuestsByOrigin(
        's1',
        QuestOrigin.selfCreated,
      );
      expect(selfCreated.map((q) => q.id).toSet(), {'q1', 'q3'});
    });
  });
}
