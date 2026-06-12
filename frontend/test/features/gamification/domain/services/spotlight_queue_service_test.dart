import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/domain/services/spotlight_queue_service.dart';

void main() {
  final now = DateTime.utc(2026, 6, 12, 9);

  SpotlightPrompt make({
    required String id,
    String studentId = 's1',
    required SpotlightType type,
    DateTime? queuedAt,
    DateTime? hideUntil,
    bool permanentlyHidden = false,
    bool isMandatory = false,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: id,
    queuedAt: queuedAt ?? now.subtract(const Duration(hours: 1)),
    hideUntil: hideUntil,
    permanentlyHidden: permanentlyHidden,
    isMandatory: isMandatory,
  );

  late MockSpotlightPromptRepository repo;
  late SpotlightQueueService queue;

  setUp(() {
    repo = MockSpotlightPromptRepository();
    queue = SpotlightQueueService(repo);
  });

  test('empty queue → null', () async {
    expect(await queue.nextPromptableFor('s1', now), isNull);
    expect(await queue.hasPromptableFor('s1', now), isFalse);
  });

  test('single teacherRec → returned', () async {
    await repo.enqueue(make(id: 'a', type: SpotlightType.teacherRec));
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'a');
  });

  test('teacherRec wins over seasonEvent', () async {
    await repo.enqueue(make(id: 'sea', type: SpotlightType.seasonEvent));
    await repo.enqueue(make(id: 'tch', type: SpotlightType.teacherRec));
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'tch');
  });

  test('seasonEvent wins over routineSuggestion', () async {
    await repo.enqueue(make(id: 'rou', type: SpotlightType.routineSuggestion));
    await repo.enqueue(make(id: 'sea', type: SpotlightType.seasonEvent));
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'sea');
  });

  test('isMandatory teacherRec wins over plain teacherRec', () async {
    await repo.enqueue(
      make(
        id: 'tch_plain',
        type: SpotlightType.teacherRec,
        queuedAt: now.subtract(const Duration(days: 5)),
      ),
    );
    await repo.enqueue(
      make(id: 'tch_must', type: SpotlightType.teacherRec, isMandatory: true),
    );
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'tch_must');
  });

  test('hidden teacherRec → fallback to seasonEvent', () async {
    await repo.enqueue(
      make(
        id: 'tch_hidden',
        type: SpotlightType.teacherRec,
        hideUntil: now.add(const Duration(days: 7)),
      ),
    );
    await repo.enqueue(make(id: 'sea', type: SpotlightType.seasonEvent));
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'sea');
  });

  test('permanentlyHidden → skipped', () async {
    await repo.enqueue(
      make(
        id: 'tch_perm',
        type: SpotlightType.teacherRec,
        permanentlyHidden: true,
      ),
    );
    await repo.enqueue(make(id: 'rou', type: SpotlightType.routineSuggestion));
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'rou');
  });

  test('hideUntil in past → not hidden, queued normally', () async {
    await repo.enqueue(
      make(
        id: 'tch_recover',
        type: SpotlightType.teacherRec,
        hideUntil: now.subtract(const Duration(hours: 1)),
      ),
    );
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'tch_recover');
  });

  test('same type, oldest queuedAt wins', () async {
    await repo.enqueue(
      make(
        id: 'new',
        type: SpotlightType.teacherRec,
        queuedAt: now.subtract(const Duration(hours: 1)),
      ),
    );
    await repo.enqueue(
      make(
        id: 'old',
        type: SpotlightType.teacherRec,
        queuedAt: now.subtract(const Duration(days: 3)),
      ),
    );
    final next = await queue.nextPromptableFor('s1', now);
    expect(next?.id, 'old');
  });

  test('all hidden → null', () async {
    await repo.enqueue(
      make(
        id: 'a',
        type: SpotlightType.teacherRec,
        hideUntil: now.add(const Duration(days: 1)),
      ),
    );
    await repo.enqueue(
      make(id: 'b', type: SpotlightType.seasonEvent, permanentlyHidden: true),
    );
    expect(await queue.nextPromptableFor('s1', now), isNull);
    expect(await queue.hasPromptableFor('s1', now), isFalse);
  });

  test('cross-student isolation', () async {
    await repo.enqueue(
      make(id: 'a', studentId: 's1', type: SpotlightType.teacherRec),
    );
    await repo.enqueue(
      make(id: 'b', studentId: 's2', type: SpotlightType.teacherRec),
    );
    final s1 = await queue.nextPromptableFor('s1', now);
    final s2 = await queue.nextPromptableFor('s2', now);
    expect(s1?.id, 'a');
    expect(s2?.id, 'b');
  });

  test(
    'full priority chain: mandatory > plain teacherRec > season > routine',
    () async {
      await repo.enqueue(
        make(id: 'rou', type: SpotlightType.routineSuggestion),
      );
      await repo.enqueue(make(id: 'sea', type: SpotlightType.seasonEvent));
      await repo.enqueue(make(id: 'tch', type: SpotlightType.teacherRec));
      await repo.enqueue(
        make(id: 'must', type: SpotlightType.teacherRec, isMandatory: true),
      );
      expect((await queue.nextPromptableFor('s1', now))?.id, 'must');

      await repo.markPermanentlyHidden('must');
      expect((await queue.nextPromptableFor('s1', now))?.id, 'tch');

      await repo.markPermanentlyHidden('tch');
      expect((await queue.nextPromptableFor('s1', now))?.id, 'sea');

      await repo.markPermanentlyHidden('sea');
      expect((await queue.nextPromptableFor('s1', now))?.id, 'rou');
    },
  );

  test('hasPromptableFor reflects emptiness', () async {
    expect(await queue.hasPromptableFor('s1', now), isFalse);
    await repo.enqueue(make(id: 'a', type: SpotlightType.teacherRec));
    expect(await queue.hasPromptableFor('s1', now), isTrue);
  });
}
