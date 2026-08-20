import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/onboarding/domain/entities/starter_sample_data.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/starter_sample_storage_provider.dart';

const _sample = StarterSampleData(
  studentId: 'student-1',
  lessonId: 'lesson-1',
  practiceLogId: 'log-1',
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('starter_sample_storage_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer containerFor(String teacherId) {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => teacherId)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts empty when the walkthrough has never run', () async {
    final sample = await containerFor(
      'teacher_a',
    ).read(starterSampleStorageProvider.future);

    expect(sample, isNull);
  });

  test('persists the created ids across containers', () async {
    final container = containerFor('teacher_a');
    await container.read(starterSampleStorageProvider.notifier).save(_sample);

    final reloaded = await containerFor(
      'teacher_a',
    ).read(starterSampleStorageProvider.future);

    expect(reloaded, _sample);
  });

  test('forgets the ids after cleanup', () async {
    final container = containerFor('teacher_a');
    final notifier = container.read(starterSampleStorageProvider.notifier);
    await notifier.save(_sample);
    await notifier.clear();

    final reloaded = await containerFor(
      'teacher_a',
    ).read(starterSampleStorageProvider.future);

    expect(reloaded, isNull);
  });

  test('keeps samples isolated per teacher', () async {
    await containerFor(
      'teacher_a',
    ).read(starterSampleStorageProvider.notifier).save(_sample);

    final other = await containerFor(
      'teacher_b',
    ).read(starterSampleStorageProvider.future);

    expect(other, isNull);
  });
}
