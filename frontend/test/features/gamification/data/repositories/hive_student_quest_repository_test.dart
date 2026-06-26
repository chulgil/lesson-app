import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';

StudentQuest _quest({
  String id = 'q1',
  String studentId = 's1',
  ActivityType? type = ActivityType.practiceMinutes,
  int currentValue = 0,
  bool isCompleted = false,
  QuestOrigin origin = QuestOrigin.selfCreated,
}) => StudentQuest(
  id: id,
  studentId: studentId,
  origin: origin,
  title: 'q',
  type: type,
  targetValue: 60,
  currentValue: currentValue,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 30),
  isCompleted: isCompleted,
);

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_quest_repo_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveStudentQuestRepository.boxName);
  });

  tearDown(() async {
    if (box.isOpen) await box.close();
    await Hive.deleteBoxFromDisk(HiveStudentQuestRepository.boxName);
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('HiveStudentQuestRepository', () {
    test('createQuest → getActiveQuests round-trip (JSON 직렬화)', () async {
      final repo = HiveStudentQuestRepository(box: box);
      await repo.createQuest(_quest(id: 'q1', currentValue: 5));

      final active = await repo.getActiveQuests('s1');
      expect(active.length, 1);
      expect(active.single.id, 'q1');
      expect(active.single.currentValue, 5);
      expect(active.single.type, ActivityType.practiceMinutes);
    });

    test('updateProgress 영속', () async {
      final repo = HiveStudentQuestRepository(box: box);
      await repo.createQuest(_quest(id: 'q1', currentValue: 5));

      final updated = await repo.updateProgress('q1', 12);
      expect(updated.currentValue, 12);
      final active = await repo.getActiveQuests('s1');
      expect(active.single.currentValue, 12);
    });

    test('markCompleted → getActiveQuests 에서 제외', () async {
      final repo = HiveStudentQuestRepository(box: box);
      await repo.createQuest(_quest(id: 'q1'));
      await repo.markCompleted('q1');
      expect(await repo.getActiveQuests('s1'), isEmpty);
    });

    test('getQuestsByOrigin 필터', () async {
      final repo = HiveStudentQuestRepository(box: box);
      await repo.createQuest(_quest(id: 'q1', origin: QuestOrigin.selfCreated));
      await repo.createQuest(_quest(id: 'q2', origin: QuestOrigin.teacherRec));

      final self = await repo.getQuestsByOrigin('s1', QuestOrigin.selfCreated);
      expect(self.map((q) => q.id), ['q1']);
    });

    test('multi-student isolation', () async {
      final repo = HiveStudentQuestRepository(box: box);
      await repo.createQuest(_quest(id: 'q1', studentId: 's1'));
      await repo.createQuest(_quest(id: 'q2', studentId: 's2'));

      expect((await repo.getActiveQuests('s1')).map((q) => q.id), ['q1']);
      expect((await repo.getActiveQuests('s2')).map((q) => q.id), ['q2']);
    });

    test('persistence — box 재-open 후에도 quest 잔존 (#422 휘발 해소)', () async {
      final repo1 = HiveStudentQuestRepository(box: box);
      await repo1.createQuest(_quest(id: 'q1', currentValue: 7));
      await box.close();

      // 앱 재시작 시뮬레이션: 같은 box 를 다시 연다.
      box = await Hive.openBox<String>(HiveStudentQuestRepository.boxName);
      final repo2 = HiveStudentQuestRepository(box: box);
      final active = await repo2.getActiveQuests('s1');
      expect(active.length, 1);
      expect(active.single.id, 'q1');
      expect(active.single.currentValue, 7);
    });

    test('updateProgress — 없는 quest → StateError', () async {
      final repo = HiveStudentQuestRepository(box: box);
      expect(() => repo.updateProgress('nope', 1), throwsA(isA<StateError>()));
    });
  });
}
