import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_spotlight_prompt_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveSpotlightPromptRepository.boxName);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveSpotlightPromptRepository.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Box name = spotlight_prompt_v1 (O2)', () {
    expect(HiveSpotlightPromptRepository.boxName, 'spotlight_prompt_v1');
  });

  test('composeKey uses :: separator', () {
    expect(HiveSpotlightPromptRepository.composeKey('s1', 'p1'), 's1::p1');
  });

  test('empty box → listForStudent returns []', () async {
    final repo = HiveSpotlightPromptRepository(box: box);
    expect(await repo.listForStudent('s1'), isEmpty);
  });

  test('enqueue persists across new repository instance', () async {
    final repo1 = HiveSpotlightPromptRepository(box: box);
    await repo1.enqueue(make(id: 'a'));

    final repo2 = HiveSpotlightPromptRepository(box: box);
    final list = await repo2.listForStudent('s1');
    expect(list.map((p) => p.id), ['a']);
  });

  test('prefix scan isolation — no leakage across students', () async {
    final repo = HiveSpotlightPromptRepository(box: box);
    await repo.enqueue(make(id: 'a', studentId: 's1'));
    await repo.enqueue(make(id: 'b', studentId: 's2'));
    await repo.enqueue(make(id: 'c', studentId: 's1'));

    final s1 = await repo.listForStudent('s1');
    final s2 = await repo.listForStudent('s2');
    expect(s1.map((p) => p.id), unorderedEquals(['a', 'c']));
    expect(s2.map((p) => p.id), ['b']);
  });

  test('mutation methods persist across instances', () async {
    final repo1 = HiveSpotlightPromptRepository(box: box);
    await repo1.enqueue(make(id: 'a'));
    await repo1.incrementDecline('a', t0);
    await repo1.setHideUntil('a', t0.add(const Duration(days: 7)));

    final repo2 = HiveSpotlightPromptRepository(box: box);
    final reloaded = (await repo2.getById('a'))!;
    expect(reloaded.declineCount, 1);
    expect(reloaded.lastShownAt, t0);
    expect(reloaded.hideUntil, t0.add(const Duration(days: 7)));
  });

  test('markPermanentlyHidden persists', () async {
    final repo1 = HiveSpotlightPromptRepository(box: box);
    await repo1.enqueue(make(id: 'a'));
    await repo1.markPermanentlyHidden('a');

    final repo2 = HiveSpotlightPromptRepository(box: box);
    final reloaded = (await repo2.getById('a'))!;
    expect(reloaded.permanentlyHidden, isTrue);
  });

  test('corrupted JSON for one key does not break listForStudent', () async {
    await box.put('s1::ok', '{}'); // partial — fromJson 실패
    final repo = HiveSpotlightPromptRepository(box: box);
    await repo.enqueue(make(id: 'good'));

    final list = await repo.listForStudent('s1');
    expect(list.map((p) => p.id), ['good']);
  });

  test('unknown id mutators throw StateError', () async {
    final repo = HiveSpotlightPromptRepository(box: box);
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
