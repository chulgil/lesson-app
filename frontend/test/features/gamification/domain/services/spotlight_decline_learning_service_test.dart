import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/domain/services/spotlight_decline_learning_service.dart';

void main() {
  final t0 = DateTime.utc(2026, 6, 12, 9);

  SpotlightPrompt make({
    required String id,
    String studentId = 's1',
    SpotlightType type = SpotlightType.teacherRec,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: id,
    queuedAt: t0.subtract(const Duration(days: 1)),
  );

  late MockSpotlightPromptRepository repo;
  late SpotlightDeclineLearningService svc;

  setUp(() {
    repo = MockSpotlightPromptRepository();
    svc = SpotlightDeclineLearningService(repo);
  });

  group('1회 거절 → 7일 cooldown', () {
    test('hideUntil = now + 7d', () async {
      await repo.enqueue(make(id: 'a'));
      final result = await svc.decline('a', t0);
      expect(result.declineCount, 1);
      expect(result.hideUntil, t0.add(const Duration(days: 7)));
      expect(result.permanentlyHidden, isFalse);
    });

    test('lastShownAt 갱신', () async {
      await repo.enqueue(make(id: 'a'));
      final result = await svc.decline('a', t0);
      expect(result.lastShownAt, t0);
    });
  });

  group('§7.3 누적 거절 boundary', () {
    test('4회 거절 → cooldown 유지 (7d)', () async {
      await repo.enqueue(make(id: 'a'));
      var t = t0;
      DateTime lastDeclineAt = t0;
      for (var i = 1; i <= 4; i++) {
        lastDeclineAt = t;
        await svc.decline('a', t);
        t = t.add(const Duration(days: 7, hours: 1)); // cooldown 통과
      }
      final reloaded = (await repo.getById('a'))!;
      expect(reloaded.declineCount, 4);
      expect(
        reloaded.hideUntil,
        lastDeclineAt.add(const Duration(days: 7)),
        reason: '마지막 거절 시점 기준 7d cooldown',
      );
      expect(reloaded.permanentlyHidden, isFalse);
    });

    test('5회 거절 → 8주 hide (56d)', () async {
      await repo.enqueue(make(id: 'a'));
      var t = t0;
      for (var i = 1; i <= 5; i++) {
        await svc.decline('a', t);
        t = t.add(const Duration(days: 1)); // boundary 확인용 짧은 간격
      }
      final reloaded = (await repo.getById('a'))!;
      expect(reloaded.declineCount, 5);
      final lastDecline = t0.add(const Duration(days: 4));
      expect(reloaded.hideUntil, lastDecline.add(const Duration(days: 56)));
      expect(reloaded.permanentlyHidden, isFalse);
    });

    test('6회 거절 → 영구 hide', () async {
      await repo.enqueue(make(id: 'a'));
      var t = t0;
      for (var i = 1; i <= 6; i++) {
        await svc.decline('a', t);
        t = t.add(const Duration(days: 1));
      }
      final reloaded = (await repo.getById('a'))!;
      expect(reloaded.declineCount, 6);
      expect(reloaded.permanentlyHidden, isTrue);
    });
  });

  group('§5.2 type 전체 영향 (해당 type)', () {
    test('5회 도달 시 같은 type 의 다른 prompt 도 8주 hide', () async {
      await repo.enqueue(make(id: 'tch1', type: SpotlightType.teacherRec));
      await repo.enqueue(make(id: 'tch2', type: SpotlightType.teacherRec));
      var t = t0;
      // tch1 5회 거절 → typeAccum=5 → tch2 도 함께 8주 hide
      for (var i = 1; i <= 5; i++) {
        await svc.decline('tch1', t);
        t = t.add(const Duration(days: 1));
      }
      final tch2 = (await repo.getById('tch2'))!;
      final lastDecline = t0.add(const Duration(days: 4));
      expect(tch2.hideUntil, lastDecline.add(const Duration(days: 56)));
    });

    test('6회 도달 시 같은 type 모든 prompt 영구 hide', () async {
      await repo.enqueue(make(id: 'tch1', type: SpotlightType.teacherRec));
      await repo.enqueue(make(id: 'tch2', type: SpotlightType.teacherRec));
      var t = t0;
      for (var i = 1; i <= 6; i++) {
        await svc.decline('tch1', t);
        t = t.add(const Duration(days: 1));
      }
      expect((await repo.getById('tch1'))!.permanentlyHidden, isTrue);
      expect((await repo.getById('tch2'))!.permanentlyHidden, isTrue);
    });

    test('다른 type 의 거절은 카운터 영향 0', () async {
      await repo.enqueue(make(id: 'tch1', type: SpotlightType.teacherRec));
      await repo.enqueue(make(id: 'sea1', type: SpotlightType.seasonEvent));
      var t = t0;
      // teacherRec 4회 거절
      for (var i = 1; i <= 4; i++) {
        await svc.decline('tch1', t);
        t = t.add(const Duration(days: 1));
      }
      // seasonEvent 1회 거절 — teacherRec 카운터에 영향 X
      await svc.decline('sea1', t);

      final tch = (await repo.getById('tch1'))!;
      final sea = (await repo.getById('sea1'))!;
      expect(tch.declineCount, 4, reason: 'teacherRec 4회');
      expect(sea.declineCount, 1, reason: 'seasonEvent 1회');
      // teacherRec typeAccum=4 → cooldown 유지 (8주 hide 미진입)
      expect(tch.hideUntil!.difference(t0).inDays, lessThan(56));
      expect(tch.permanentlyHidden, isFalse);
      expect(sea.permanentlyHidden, isFalse);
    });

    test('다른 학생의 같은 type 거절은 카운터 영향 0', () async {
      await repo.enqueue(make(id: 'a', studentId: 's1'));
      await repo.enqueue(make(id: 'b', studentId: 's2'));
      var t = t0;
      for (var i = 1; i <= 5; i++) {
        await svc.decline('a', t);
        t = t.add(const Duration(days: 1));
      }
      final b = (await repo.getById('b'))!;
      expect(b.declineCount, 0);
      expect(b.hideUntil, isNull);
      expect(b.permanentlyHidden, isFalse);
    });
  });

  group('typeAccumulatorFor', () {
    test('같은 학생 + type 의 declineCount 합', () async {
      await repo.enqueue(make(id: 'tch1', type: SpotlightType.teacherRec));
      await repo.enqueue(make(id: 'tch2', type: SpotlightType.teacherRec));
      await repo.enqueue(make(id: 'sea1', type: SpotlightType.seasonEvent));
      var t = t0;
      await svc.decline('tch1', t);
      t = t.add(const Duration(days: 7, hours: 1));
      await svc.decline('tch2', t);
      t = t.add(const Duration(days: 7, hours: 1));
      await svc.decline('sea1', t);

      expect(await svc.typeAccumulatorFor('s1', SpotlightType.teacherRec), 2);
      expect(await svc.typeAccumulatorFor('s1', SpotlightType.seasonEvent), 1);
      expect(
        await svc.typeAccumulatorFor('s1', SpotlightType.routineSuggestion),
        0,
      );
    });
  });

  group('상수 노출', () {
    test('cooldown = 7d, weeksHide = 56d', () {
      expect(SpotlightDeclineLearningService.cooldown, const Duration(days: 7));
      expect(
        SpotlightDeclineLearningService.weeksHide,
        const Duration(days: 56),
      );
    });

    test('cumulativeBeforeWeeksHide=5, cumulativeBeforePermanent=6', () {
      expect(SpotlightDeclineLearningService.cumulativeBeforeWeeksHide, 5);
      expect(SpotlightDeclineLearningService.cumulativeBeforePermanent, 6);
    });
  });
}
