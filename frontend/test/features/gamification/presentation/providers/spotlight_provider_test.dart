import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/presentation/providers/spotlight_provider.dart';

void main() {
  // 2026-06-12 (금요일) — KST 자정 / 월요일 자정 검사 fixture.
  final now = DateTime.utc(2026, 6, 12, 9);

  ProviderContainer makeContainer(MockSpotlightPromptRepository repo) =>
      ProviderContainer(
        overrides: [spotlightPromptRepositoryProvider.overrideWithValue(repo)],
      );

  SpotlightPrompt make({
    required String id,
    String studentId = 's1',
    SpotlightType type = SpotlightType.teacherRec,
    DateTime? queuedAt,
    DateTime? lastShownAt,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: id,
    queuedAt: queuedAt ?? now.subtract(const Duration(hours: 1)),
    lastShownAt: lastShownAt,
  );

  group('currentSpotlightForCelebration', () {
    test('eligible + queue 보유 → 첫 후보 반환', () async {
      final repo = MockSpotlightPromptRepository();
      await repo.enqueue(make(id: 'tch', type: SpotlightType.teacherRec));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result?.id, 'tch');
    });

    test('session < 5분 → null', () async {
      final repo = MockSpotlightPromptRepository();
      await repo.enqueue(make(id: 'tch'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 4),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result, isNull);
    });

    test('queue 비어있음 → null', () async {
      final repo = MockSpotlightPromptRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result, isNull);
    });

    test('오늘 (KST) 이미 1회 노출 → null', () async {
      final repo = MockSpotlightPromptRepository();
      // KST 자정: now (UTC 9시) = KST 18시. 같은 KST 일자 = 2026-06-12 KST.
      // KST 자정 = 2026-06-11 15:00 UTC. lastShownAt 그 이후면 오늘 노출.
      await repo.enqueue(
        make(
          id: 'shown_today',
          lastShownAt: now.subtract(const Duration(hours: 2)),
        ),
      );
      await repo.enqueue(make(id: 'tch_new'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result, isNull);
    });

    test('주간 (KST 월요일 시작) 이미 2회 노출 → null', () async {
      final repo = MockSpotlightPromptRepository();
      // 2026-06-12 (금) UTC 9시 — KST 18시. 이번 주 월요일 KST = 2026-06-08.
      // 월요일 KST 자정 = 2026-06-07 15:00 UTC.
      // 그 이후 + 어제 (이미 노출) 2회.
      await repo.enqueue(
        make(id: 'mon', lastShownAt: DateTime.utc(2026, 6, 8, 9)),
      );
      await repo.enqueue(
        make(id: 'wed', lastShownAt: DateTime.utc(2026, 6, 10, 9)),
      );
      await repo.enqueue(make(id: 'tch_new'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result, isNull);
    });

    test('14세 미만 + 부모 동의 X → null', () async {
      final repo = MockSpotlightPromptRepository();
      await repo.enqueue(make(id: 'tch'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: true,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result, isNull);
    });

    test('14세 미만 + 부모 동의 O → 후보 반환', () async {
      final repo = MockSpotlightPromptRepository();
      await repo.enqueue(make(id: 'tch'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: true,
          studentHasParentConsent: true,
        ).future,
      );

      expect(result?.id, 'tch');
    });

    test('우선순위 chain 통과 — Queue.nextPromptableFor 결과 그대로 반환', () async {
      final repo = MockSpotlightPromptRepository();
      await repo.enqueue(
        make(id: 'rou', type: SpotlightType.routineSuggestion),
      );
      await repo.enqueue(make(id: 'sea', type: SpotlightType.seasonEvent));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        currentSpotlightForCelebrationProvider(
          's1',
          sessionDuration: const Duration(minutes: 10),
          now: now,
          studentIsUnder14: false,
          studentHasParentConsent: false,
        ).future,
      );

      expect(result?.id, 'sea', reason: 'seasonEvent > routineSuggestion');
    });
  });
}
