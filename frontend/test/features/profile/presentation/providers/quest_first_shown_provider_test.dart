import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_first_shown_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'lessonaza_quest_first_shown_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('초기값은 null — markShown 호출 전', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final value = await container.read(questFirstShownProvider.future);
    expect(value, isNull);
  });

  test('markShown 호출 후 현재 시각으로 set', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(questFirstShownProvider.future);
    await container.read(questFirstShownProvider.notifier).markShown();

    final value = await container.read(questFirstShownProvider.future);
    expect(value, isNotNull);
    expect(DateTime.now().difference(value!).inSeconds, lessThan(5));
  });

  test('isWithin — markShown 직후 true, 6분 후 false', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(questFirstShownProvider.future);
    await container.read(questFirstShownProvider.notifier).markShown();
    final value = await container.read(questFirstShownProvider.future);

    expect(QuestFirstShown.isWithin(value), isTrue);
    expect(
      QuestFirstShown.isWithin(
        value,
        now: DateTime.now().add(const Duration(minutes: 6)),
      ),
      isFalse,
    );
  });

  test('isWithin(null) == false — 미완료 상태', () {
    expect(QuestFirstShown.isWithin(null), isFalse);
  });

  test('Hive 영속화 — container 재생성 후에도 값 유지', () async {
    final container1 = ProviderContainer();
    await container1.read(questFirstShownProvider.future);
    await container1.read(questFirstShownProvider.notifier).markShown();
    final value1 = await container1.read(questFirstShownProvider.future);
    container1.dispose();

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final value2 = await container2.read(questFirstShownProvider.future);

    expect(value1, isNotNull);
    expect(value2, isNotNull);
    expect(value2!.toIso8601String(), equals(value1!.toIso8601String()));
  });
}
