import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';

void main() {
  test('QuestOrigin has 6 values', () {
    expect(QuestOrigin.values.length, 6);
  });

  test('QuestOrigin has all spec-defined origins', () {
    expect(
      QuestOrigin.values,
      containsAll([
        QuestOrigin.ambient,
        QuestOrigin.selfCreated,
        QuestOrigin.systemRoutine,
        QuestOrigin.lessonDerived,
        QuestOrigin.teacherRec,
        QuestOrigin.seasonEvent,
      ]),
    );
  });
}
