import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';

void main() {
  group('StudentQuest', () {
    final base = StudentQuest(
      id: 'q1',
      studentId: 's1',
      origin: QuestOrigin.selfCreated,
      title: '스케일 5분',
      type: ActivityType.practiceMinutes,
      targetValue: 5,
      currentValue: 0,
      startDate: DateTime(2026, 6, 11),
      endDate: DateTime(2026, 6, 18),
    );

    test('progress = currentValue / targetValue (clamped 0..1)', () {
      expect(base.progress, 0.0);
      expect(base.copyWith(currentValue: 3).progress, 0.6);
      expect(base.copyWith(currentValue: 5).progress, 1.0);
      expect(base.copyWith(currentValue: 10).progress, 1.0);
    });

    test('isCompleted false by default, true when manually set', () {
      expect(base.isCompleted, false);
      expect(base.copyWith(isCompleted: true).isCompleted, true);
    });

    test('json round-trip preserves all fields', () {
      final json = base.toJson();
      final restored = StudentQuest.fromJson(json);
      expect(restored.id, base.id);
      expect(restored.studentId, base.studentId);
      expect(restored.origin, base.origin);
      expect(restored.title, base.title);
      expect(restored.type, base.type);
      expect(restored.targetValue, base.targetValue);
      expect(restored.currentValue, base.currentValue);
      expect(restored.startDate, base.startDate);
      expect(restored.endDate, base.endDate);
      expect(restored.isCompleted, base.isCompleted);
      expect(restored.completedAt, base.completedAt);
    });

    test('wire values unchanged after ActivityType rename (#965)', () {
      // 직렬화 문자열 값은 ChallengeType 시절과 동일해야 기존 저장 데이터가 디코드됨.
      expect(base.toJson()['type'], 'practiceMinutes');
      final decoded = StudentQuest.fromJson({...base.toJson(), 'type': 'streak'});
      expect(decoded.type, ActivityType.streak);
    });
  });
}
