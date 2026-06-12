import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';

void main() {
  final t0 = DateTime.utc(2026, 6, 12, 9);

  SpotlightPrompt make({
    String id = 'p1',
    String studentId = 's1',
    SpotlightType type = SpotlightType.teacherRec,
    String title = 'sample',
    int declineCount = 0,
    DateTime? hideUntil,
    bool permanentlyHidden = false,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: title,
    queuedAt: t0,
    declineCount: declineCount,
    hideUntil: hideUntil,
    permanentlyHidden: permanentlyHidden,
  );

  late MockSpotlightPromptRepository repo;

  setUp(() {
    repo = MockSpotlightPromptRepository();
  });

  test('enqueue + listForStudent round-trip', () async {
    await repo.enqueue(make(id: 'a'));
    await repo.enqueue(make(id: 'b'));
    final list = await repo.listForStudent('s1');
    expect(list.map((p) => p.id), unorderedEquals(['a', 'b']));
  });

  test('listForStudent does not leak across students', () async {
    await repo.enqueue(make(id: 'a', studentId: 's1'));
    await repo.enqueue(make(id: 'b', studentId: 's2'));
    final s1 = await repo.listForStudent('s1');
    final s2 = await repo.listForStudent('s2');
    expect(s1.map((p) => p.id), ['a']);
    expect(s2.map((p) => p.id), ['b']);
  });

  test('getById returns null when missing', () async {
    final got = await repo.getById('missing');
    expect(got, isNull);
  });

  test('markShown updates lastShownAt only', () async {
    await repo.enqueue(make(id: 'a'));
    final shown = await repo.markShown('a', t0);
    expect(shown.lastShownAt, t0);
    expect(shown.declineCount, 0);
    expect(shown.hideUntil, isNull);
  });

  test('incrementDecline raises count + records lastShownAt', () async {
    await repo.enqueue(make(id: 'a'));
    final once = await repo.incrementDecline('a', t0);
    expect(once.declineCount, 1);
    expect(once.lastShownAt, t0);

    final twice = await repo.incrementDecline(
      'a',
      t0.add(const Duration(days: 7)),
    );
    expect(twice.declineCount, 2);
    expect(twice.lastShownAt, t0.add(const Duration(days: 7)));
  });

  test('setHideUntil persists hide cooldown', () async {
    await repo.enqueue(make(id: 'a'));
    final until = t0.add(const Duration(days: 7));
    final hidden = await repo.setHideUntil('a', until);
    expect(hidden.hideUntil, until);
    expect(hidden.permanentlyHidden, isFalse);
  });

  test('markPermanentlyHidden sets the flag', () async {
    await repo.enqueue(make(id: 'a'));
    final hidden = await repo.markPermanentlyHidden('a');
    expect(hidden.permanentlyHidden, isTrue);
  });

  test('unknown id mutators throw StateError (not silent no-op)', () async {
    await expectLater(() => repo.markShown('nope', t0), throwsStateError);
    await expectLater(
      () => repo.incrementDecline('nope', t0),
      throwsStateError,
    );
    await expectLater(() => repo.setHideUntil('nope', t0), throwsStateError);
    await expectLater(
      () => repo.markPermanentlyHidden('nope'),
      throwsStateError,
    );
  });
}
