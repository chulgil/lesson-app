import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/auth/presentation/providers/active_discipline_provider.dart';

/// #979-A — persisted discipline selection + derived active discipline.
/// #979-B registers fitness, so [activeDiscipline] resolves the persisted id
/// (music or fitness), falling back to music for null / legacy / unknown ids.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('active_discipline_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer containerFor(String userId) {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => userId)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SelectedDisciplineStorage', () {
    test('defaults to no selection for a fresh user', () async {
      final container = containerFor('user_a');
      final id = await container.read(selectedDisciplineStorageProvider.future);
      expect(id, isNull);
    });

    test('persists the selected discipline across reload', () async {
      final container = containerFor('user_a');
      await container
          .read(selectedDisciplineStorageProvider.notifier)
          .select('music');
      await container.read(selectedDisciplineStorageProvider.future);

      final reloaded = containerFor('user_a');
      final id = await reloaded.read(selectedDisciplineStorageProvider.future);
      expect(id, 'music');
    });

    test('keeps selections isolated by user id', () async {
      final userA = containerFor('user_a');
      await userA
          .read(selectedDisciplineStorageProvider.notifier)
          .select('music');
      await userA.read(selectedDisciplineStorageProvider.future);

      final userB = containerFor('user_b');
      final idB = await userB.read(selectedDisciplineStorageProvider.future);
      expect(idB, isNull, reason: 'user B must not see user A selection');
    });
  });

  group('activeDiscipline', () {
    test('resolves to music (fallback) when nothing is persisted', () async {
      final container = containerFor('user_a');
      await container.read(selectedDisciplineStorageProvider.future);
      expect(container.read(activeDisciplineProvider), DisciplineRegistry.music);
    });

    test('resolves the persisted discipline (music)', () async {
      final container = containerFor('user_a');
      await container
          .read(selectedDisciplineStorageProvider.notifier)
          .select('music');
      await container.read(selectedDisciplineStorageProvider.future);
      expect(container.read(activeDisciplineProvider), DisciplineRegistry.music);
    });

    test('resolves the persisted fitness discipline (#979-B)', () async {
      final container = containerFor('user_a');
      await container
          .read(selectedDisciplineStorageProvider.notifier)
          .select('fitness');
      await container.read(selectedDisciplineStorageProvider.future);
      expect(
        container.read(activeDisciplineProvider),
        DisciplineRegistry.fitness,
      );
    });

    test('resolves the persisted language discipline (#1102)', () async {
      final container = containerFor('user_a');
      await container
          .read(selectedDisciplineStorageProvider.notifier)
          .select('language');
      await container.read(selectedDisciplineStorageProvider.future);
      expect(
        container.read(activeDisciplineProvider),
        DisciplineRegistry.language,
      );
    });

    test('falls back to music for an unregistered persisted id', () async {
      // A stale / unknown id must not break resolution.
      final container = containerFor('user_a');
      await container
          .read(selectedDisciplineStorageProvider.notifier)
          .select('unknown_discipline');
      await container.read(selectedDisciplineStorageProvider.future);
      expect(
        container.read(activeDisciplineProvider),
        DisciplineRegistry.fallback,
      );
    });
  });
}
